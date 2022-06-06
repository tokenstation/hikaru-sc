require('dotenv').config();

module.exports = {
    compilers: {
        solc: {
            version: "0.8.6", // A version or constraint - Ex. "^0.5.0"
                                // Can also be set to "native" to use a native solc
            /*docker: <boolean>, // Use a version obtained through docker
            parser: "solcjs",  // Leverages solc-js purely for speedy parsing */
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200   // Optimize for how many times you intend to run the code
                },
            /* evmVersion: <string> // Default: "petersburg" */
            }
        }
    },

    networks: {
        development: {
            host: "127.0.0.1",
            port: 8545,
            network_id: '*',
            gas: 30000000
        }
    },

    mocha: {
        useColors: false,
        slow: 200,
        timeout: 999999
    }
};
