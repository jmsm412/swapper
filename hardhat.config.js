require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("hardhat-gas-reporter");
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	networks: {
		hardhat: {
			forking: {
				url: "https://eth-mainnet.alchemyapi.io/v2/DVoO1-qsfYz7eRuyS6He_LAO82-ZWGuQ"
			}
		}
	},
	solidity: {
		compilers: [{
			version: "0.8.4"
		},{
			version: "0.5.12"
		}]
	},
	gasReporter: {
		currency: 'USD'
	}
};
