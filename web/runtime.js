Module.preRun = Module.preRun || [];
Module.preRun.push(function () {
    addRunDependency('dragon-data');
    (async function () {
        const response = await fetch('assets/manifest.json', {cache: 'no-cache'});
        if (!response.ok) throw new Error('无法读取游戏资源目录');
        const manifest = await response.json();
        const packs = new Map();
        FS.mkdirTree('/game');
        for (const [path, entry] of Object.entries(manifest.files)) {
            const parent = path.slice(0, path.lastIndexOf('/'));
            FS.mkdirTree(parent);
            FS.writeFile(path, new Uint8Array());
            const node = FS.lookupPath(path).node;
            node.dragonBundle = entry[0];
            node.usedBytes = entry[1];
        }

        function loadPack(name) {
            if (!packs.has(name)) {
                packs.set(name, (async function () {
                    Module.setStatus('正在加载游戏资源…');
                    const res = await fetch('assets/' + name);
                    if (!res.ok) throw new Error('游戏资源下载失败，请刷新重试');
                    const stream = res.body.pipeThrough(new DecompressionStream('gzip'));
                    const data = new Uint8Array(await new Response(stream).arrayBuffer());
                    for (const [path, offset, size] of manifest.bundles[name]) {
                        const node = FS.lookupPath(path).node;
                        node.contents = data.subarray(offset, offset + size);
                        node.usedBytes = size;
                        node.dragonLoaded = true;
                    }
                    Module.setStatus('');
                })());
            }
            return packs.get(name);
        }

        // The native interpreter retains its synchronous file API. Asyncify
        // suspends only the first open while the containing bundle is fetched.
        const open = FS.open;
        FS.open = function (path, flags, mode) {
            let node;
            try { node = FS.lookupPath(path, {follow: true}).node; } catch (_) {}
            if (node && node.dragonBundle) {
                if (!node.dragonLoaded) {
                    Asyncify.handleAsync(() => loadPack(node.dragonBundle));
                } else if (Asyncify.state === 2) {
                    Asyncify.handleAsync(() => Promise.resolve());
                }
            }
            return open.call(this, path, flags, mode);
        };

        // Keep fresh-game templates in the packaged data. Only player saves
        // live on the persistent filesystem, so updates cannot replace them.
        FS.mkdirTree('/persist');
        FS.mount(IDBFS, {autoPersist: true}, '/persist');
        await new Promise((resolve, reject) => FS.syncfs(true, error => error ? reject(error) : resolve()));
        for (let slot = 1; slot <= 20; ++slot) {
            for (const prefix of ['r', 's', 'd']) {
                const name = prefix + slot + '.grp';
                FS.symlink('/persist/' + name, '/game/save/' + name);
            }
        }
        FS.chdir('/game');
        removeRunDependency('dragon-data');
    })().catch(error => {
        Module.setStatus(error.message);
        console.error(error);
    });
});
