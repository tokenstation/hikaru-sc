module.exports = {
    networks: {
        tron_dev: {
            privateKey: '212207363424d4590c01c206cfdb7f5b6af4f86718f0f8e6c234c8356f3c1e54',
            feeLimit: 1000000000,
            userFeePercentage: 100,
            fullHost: "http://127.0.0.1:9090",
            network_id: "*"
        },
        compilers: {
            solc: {
                version: '0.8.6'
            }
        }
    },

    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        },
        evmVersion: 'istanbul'
    }
}