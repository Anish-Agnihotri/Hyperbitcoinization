# Hyperbitcoinization

Simple smart contract that configures a 1M [USDC](https://www.circle.com/en/usdc) vs 1 [Wrapped Bitcoin](https://wbtc.network/) 90-day term bet, inspired by [Balaji's](https://twitter.com/balajis/status/1636827051419389952) tweet.

1. Anyone can `createBet()` initializing a bet between two parties
2. Parties `A` and `B` deposit their funds, contract marks second deposit as `startTimestamp`
3. Bet is frozen for 90 days from `startTimestamp`
4. After 90 days, anyone call call `settleBet()`, using the [Chainlink BTC/USD](https://data.chain.link/ethereum/mainnet/crypto-usd/btc-usd) oracle to settle the bet

## License

[GNU Affero GPL v3.0](https://github.com/Anish-Agnihotri/Hyperbitcoinization/blob/master/LICENSE)
