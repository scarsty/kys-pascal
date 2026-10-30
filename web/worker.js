export default {
    fetch(request, env) {
        return env.ASSETS.fetch(request);
    }
};
