# vyper-staking-mix

A bare-bones implementation of the Ethereum [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20), written in [Vyper](https://github.com/vyperlang/vyper) & a barebones staking contract.

For [Solidity](https://github.com/ethereum/solidity) tokens, check out [`token-mix`](https://github.com/brownie-mix/token-mix).

## Installation

1. [Install Brownie](https://eth-brownie.readthedocs.io/en/stable/install.html), if you haven't already.

YOU WILL NOT BE ABLE TO USE THE MIX UNTIL THIS IS MERGED TO THE MIXES. PLEASE CLONE THIS GITHUB IN THE MEANTIME. 

2. Download the mix.

    ```bash
    brownie bake vyper-staking
    ```

## Basic Use

This mix provides a [basic staking contract](contracts/Staking.vy) and a [simple token template](contracts/Token.vy) upon which you can build your own staking contracts and tokens.

Unit tests are in progress - "unit tests providing 100% coverage for core ERC20 functionality."

To interact with a deployed contract in a local environment, start by opening the console:

```bash
brownie console
```

Next, deploy a token you will use for rewards:

```python
>>> reward_token = Token.deploy("reward token", "RWRD", 18, 1e28, {'from': accounts[0]})

Transaction sent: 0x5d4a12cb6dd3eae0f60db232c4fe72d7f50490449bd3bd1a08941a2d46eb14af
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 0
  Token.constructor confirmed - Block: 1   Gas used: 482685 (4.02%)
  Token deployed at: 0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87
```

Next, deploy a token you will use for staking. 

```python
>>> stake_token = Token.deploy("stake token", "STAKE", 18, 1e21, {'from': accounts[0]})

Transaction sent: 0xbb5fb7f74d6425a7b726e3d684d03b77317dedc15ee382225ffc6467e015aaa3
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 1
  Token.constructor confirmed - Block: 2   Gas used: 482685 (4.02%)
  Token deployed at: 0x602C71e4DAC47a042Ee7f46E0aee17F94A3bA0B6
```

You now have 2 token contracts deployed, one with a balance of `1e28` and one with a balance of `1e21` assigned to `accounts[0]`:

```python
>>> reward_token
<Token Contract '0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87'>

>>> stake_token
<Token Contract '0x602C71e4DAC47a042Ee7f46E0aee17F94A3bA0B6'>

>>> reward_token.balanceOf(accounts[0])
10000000000000000000000000000

>>> stake_token.balanceOf(accounts[0])
1000000000000000000000

>>> staking = Staking.deploy(stake_token,reward_token,60, {'from': accounts[0]}) # one token per minute per staked token

Transaction sent: 0xdda9cb1c85c27522cce255d65825af4c3a828fa9f17c97b999c24139366cbe1c
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 2
  Staking.constructor confirmed - Block: 3   Gas used: 630353 (5.25%)
  Staking deployed at: 0xE7eD6747FaC5360f88a2EFC03E00d25789F69291

>>> reward_token.transfer(staking, reward_token.balanceOf(accounts[0]), {'from': accounts[0]})
Transaction sent: 0x6fd223cf440e6f6e629785c2bdd6e611ea3adef4118971c0b9d94b0d680ca044
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 3
  Token.transfer confirmed - Block: 4   Gas used: 36552 (0.30%)

<Transaction '0x6fd223cf440e6f6e629785c2bdd6e611ea3adef4118971c0b9d94b0d680ca044'>

>>> stake_token.approve(staking,stake_token.balanceOf(accounts[0]),{'from':accounts[0]})

Transaction sent: 0x03717f6837e1b8879ad79f3ea5af3ee000368f4de88fa99357074b39ecd447b5
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 5
  Token.approve confirmed - Block: 6   Gas used: 43770 (0.36%)

<Transaction '0x03717f6837e1b8879ad79f3ea5af3ee000368f4de88fa99357074b39ecd447b5'>

>>> staking.stake(stake_token.balanceOf(accounts[0]),{'from':accounts[0]})

Transaction sent: 0x8cdb069bc6e8d4cd4235804a2f12052183c0a69e01b56caaf3ab14c95b878ad0
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 6
  Staking.stake confirmed - Block: 7   Gas used: 77903 (0.65%)

<Transaction '0x8cdb069bc6e8d4cd4235804a2f12052183c0a69e01b56caaf3ab14c95b878ad0'>

>>> staking.staked_balance(accounts[0])
1000000000000000000000

>>> chain.sleep(86400)

>>> chain.mine()

>>> staking.earned(accounts[0]) * 10 ** -18
1440366.6666666667

>>> staking.redeem({'from':accounts[0]})

Transaction sent: 0x80b7859d55b96587e97c241783b2d18c05df731858adf3e4b300c0f949080a2d
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 6
  Staking.redeem confirmed - Block: 8   Gas used: 69244 (0.58%)

<Transaction '0x80b7859d55b96587e97c241783b2d18c05df731858adf3e4b300c0f949080a2d'>

>>> reward_token.balanceOf(accounts[0])
1440950000000000000000000

```

Now you can get your ABI. 

```python
>>> staking.abi
```

## Testing

TESTING IS STILL IN PROGRESS

To run the tests:

```bash
brownie test
```

The unit tests included in this mix are very generic and should work with any ERC20 compliant smart contract. To use them in your own project, all you must do is modify the deployment logic in the [`tests/conftest.py::token`](tests/conftest.py) fixture.

## Resources

To get started with Brownie:

* Check out the other [Brownie mixes](https://github.com/brownie-mix/) that can be used as a starting point for your own contracts. They also provide example code to help you get started.
* ["Getting Started with Brownie"](https://medium.com/@iamdefinitelyahuman/getting-started-with-brownie-part-1-9b2181f4cb99) is a good tutorial to help you familiarize yourself with Brownie.
* For more in-depth information, read the [Brownie documentation](https://eth-brownie.readthedocs.io/en/stable/).


Any questions? Join our [Gitter](https://gitter.im/eth-brownie/community) channel to chat and share with others in the community.

## License

This project is licensed under the [MIT license](LICENSE).
