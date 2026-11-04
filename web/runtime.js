Module.preRun = Module.preRun || [];
Module.preRun.push(function () {
    addRunDependency('dragon-data');
    (async function () {
        const manifest = await Module.assetManifest;
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

        const foregroundPacks = new Set();
        const loadedPacks = new Set();
        const labels = {scenes:'场景资源',world:'大地图资源',battle:'战斗资源',fonts:'字体',heads:'头像',portraits:'头像',events:'剧情',dialogue:'对话',save:'游戏数据',effects:'招式特效','text-conversion':'文字数据'};

        function packLabel(name) {
            return Object.entries(labels).find(([prefix])=>name.startsWith(prefix+'-'))?.[1] || '游戏资源';
        }

        function loadPack(name, foreground = true) {
            if (loadedPacks.has(name)) return Promise.resolve();
            const label = packLabel(name);
            if (foreground && !foregroundPacks.has(name)) {
                foregroundPacks.add(name);
                Module.assetStarted(name,label);
            }
            if (!packs.has(name)) {
                packs.set(name, (async function () {
                    const bytes = await (Module.startupPacks.get(name) || Module.fetchBinary('assets/' + name, manifest.sizes[name],foreground));
                    if (foregroundPacks.has(name)) Module.assetDecoding(label);
                    const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
                    const data = new Uint8Array(await new Response(stream).arrayBuffer());
                    for (const [path, offset, size] of manifest.bundles[name]) {
                        const node = FS.lookupPath(path).node;
                        node.contents = data.subarray(offset, offset + size);
                        node.usedBytes = size;
                        node.dragonLoaded = true;
                    }
                    loadedPacks.add(name);
                    if (foregroundPacks.delete(name)) Module.assetFinished(name,label);
                })().catch(error => {
                    Module.onAbort(error);
                    throw error;
                }));
            }
            return packs.get(name);
        }

        Module.prepareMusic = function (track) {
            if (!Module.hasInteracted) return false;
            const mp3 = '/game/music/' + track + '.mp3';
            const paths = manifest.files[mp3] ? [mp3] : ['/game/music/' + track + '.mid','/game/music/mid.sf2'];
            let complete = true;
            for (const path of paths) {
                let node;
                try { node = FS.lookupPath(path).node; } catch (_) { continue; }
                if (!node.dragonLoaded) {
                    complete = false;
                    loadPack(node.dragonBundle,false).catch(()=>{});
                }
            }
            return complete;
        };

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
        await Promise.all(manifest.startup.map(name => loadPack(name)));
        FS.chdir('/game');
        removeRunDependency('dragon-data');
    })().catch(error => {
        Module.onAbort(error);
    });
});
