ObjC.import('Foundation');

function fail(message) {
    throw new Error(message);
}

function readText(path) {
    const error = Ref();
    const value = $.NSString.stringWithContentsOfFileEncodingError(
        path,
        $.NSUTF8StringEncoding,
        error
    );
    if (!value) {
        fail('Cannot read Local State: ' + path);
    }
    return ObjC.unwrap(value);
}

function writeText(path, text) {
    const error = Ref();
    const value = $(text);
    const ok = value.writeToFileAtomicallyEncodingError(
        path,
        true,
        $.NSUTF8StringEncoding,
        error
    );
    if (!ok) {
        fail('Cannot write Local State: ' + path);
    }
}

function readState(path) {
    try {
        return JSON.parse(readText(path));
    } catch (error) {
        fail('Local State is not valid JSON: ' + error.message);
    }
}

function profileEligibility(state) {
    const result = {};
    const cache = state.profile && state.profile.info_cache;
    if (!cache || typeof cache !== 'object') {
        return result;
    }
    Object.keys(cache).sort().forEach(function (name) {
        result[name] = cache[name].is_glic_eligible;
    });
    return result;
}

function summary(state) {
    return {
        variations_country: state.variations_country,
        variations_safe_seed_permanent_consistency_country:
            state.variations_safe_seed_permanent_consistency_country,
        variations_safe_seed_session_consistency_country:
            state.variations_safe_seed_session_consistency_country,
        variations_permanent_consistency_country:
            state.variations_permanent_consistency_country,
        glic_launcher_enabled:
            state.glic && state.glic.launcher_enabled,
        profile_is_glic_eligible: profileEligibility(state)
    };
}

function repair(state, region) {
    state.variations_country = region;

    if ('variations_safe_seed_permanent_consistency_country' in state) {
        state.variations_safe_seed_permanent_consistency_country = region;
    }
    if ('variations_safe_seed_session_consistency_country' in state) {
        state.variations_safe_seed_session_consistency_country = region;
    }
    if (Array.isArray(state.variations_permanent_consistency_country) &&
        state.variations_permanent_consistency_country.length >= 2) {
        state.variations_permanent_consistency_country[1] = region;
    }

    if (!state.glic || typeof state.glic !== 'object') {
        state.glic = {};
    }
    state.glic.launcher_enabled = true;

    const cache = state.profile && state.profile.info_cache;
    if (cache && typeof cache === 'object') {
        Object.keys(cache).forEach(function (name) {
            if (cache[name] && typeof cache[name] === 'object') {
                cache[name].is_glic_eligible = true;
            }
        });
    }
}

function run(argv) {
    if (argv.length < 2) {
        fail('Usage: patch-local-state.js inspect|repair PATH [REGION]');
    }

    const command = argv[0];
    const path = argv[1];
    const state = readState(path);

    if (command === 'inspect') {
        return JSON.stringify(summary(state), null, 2);
    }
    if (command === 'repair') {
        const region = (argv[2] || 'us').toLowerCase();
        if (!/^[a-z]{2}$/.test(region)) {
            fail('REGION must be a two-letter country code.');
        }
        repair(state, region);
        writeText(path, JSON.stringify(state));
        return JSON.stringify(summary(state), null, 2);
    }

    fail('Unknown command: ' + command);
}

