# @version ^0.2.0

"""
@title Bare-bones Staking implementation
@notice uses the ERC-20 token standard as defined at
        https://eips.ethereum.org/EIPS/eip-20
"""

from vyper.interfaces import ERC20

## Type assignments

staked_balance: public(HashMap[address, uint256])
deposit_timestamp: public(HashMap[address, uint256])
points: public(HashMap[address, uint256])

owner: public(address)
staking_token: public(ERC20)
reward_token: public(ERC20)
paused: public(bool)
rate: public(uint256) #seconds to earn one reward token per staking token staked

## Event Logs

event Staked: 
    sender: indexed(address)
    amount: uint256

event Withdrawal: 
    sender: indexed(address)
    amount: uint256

event Redeemed:
    sender: indexed(address)
    amount: uint256

event Paused:
    sender: indexed(address)
    paused: bool

event RateUpdated:
    sender: indexed(address)
    rate: uint256

#constructor function

@external
def __init__(_staking_token: address, _reward_token: address, _rate: uint256):
    self.staking_token = ERC20(_staking_token)
    self.reward_token = ERC20(_reward_token)
    self.rate = _rate
    self.owner = msg.sender
    self.paused = False

## Reward functions

@view
@internal
def _reward(account: address) -> uint256:
    return (block.timestamp - self.deposit_timestamp[account]) * self.staked_balance[account] / self.rate
    # vyper requires erc20metadata interface or self.reward_token.decimals() doesn't exist

#reentrancy lock here?
@internal
def _accrue_points(sender: address) -> bool:
    self.points[sender] = self._reward(sender)
    self.deposit_timestamp[sender] = block.timestamp
    return True

@view
@external
def earned(account: address) -> uint256:
    return self._reward(account) + self.points[account]

## User functions 

@external
def stake(amount: uint256) -> bool:
    assert self.paused == False
    self._accrue_points(msg.sender)
    self.staking_token.transferFrom(msg.sender, self, amount)
    self.staked_balance[msg.sender] = self.staked_balance[msg.sender] + amount
    self.deposit_timestamp[msg.sender] = block.timestamp
    log Staked(msg.sender, amount)
    return True

@internal
def _withdraw(account: address, amount: uint256) -> bool:
    assert self.staked_balance[account] >= amount
    self._accrue_points(account)    
    if self.staked_balance[account] > amount:
        self.deposit_timestamp[account] = block.timestamp
    else:
        self.deposit_timestamp[account] = 0
    self.staked_balance[account] = self.staked_balance[account] - amount
    self.staking_token.transfer(account, amount)
    log Withdrawal(account, amount)
    return True

@external 
def withdraw(amount:uint256) -> bool:
    self._withdraw(msg.sender,amount)
    return True


@internal
def _redeem(account: address) -> bool:
    assert self.paused == False
    self._accrue_points(account)
    reward: uint256 = self.points[account]
    if reward > self.reward_token.balanceOf(self):
        reward = self.reward_token.balanceOf(self)
    self.points[account] = 0
    self.deposit_timestamp[account] = block.timestamp
    self.reward_token.transfer(account, reward)
    log Redeemed(account, reward)
    return True

@external
def redeem() -> bool:
    self._redeem(msg.sender)
    return True

@external
def exit() -> bool:
    self._redeem(msg.sender)
    self._withdraw(msg.sender, self.staked_balance[msg.sender])
    return True

## Admin functions

@external
def update_rate(new_rate: uint256) -> bool:
    assert msg.sender == self.owner
    self.rate = new_rate
    log RateUpdated(msg.sender, self.rate)
    return True

@external
def pause(pause: bool) -> bool:
    assert msg.sender == self.owner
    self.paused = pause
    log Paused(msg.sender, self.paused)
    return True

@external
def update_owner(new_owner: address) -> bool:
    assert msg.sender == self.owner
    self.owner = new_owner
    return True

@external
def remove_reward_tokens() -> bool:
    assert msg.sender == self.owner
    self.reward_token.transfer(self.owner, self.reward_token.balanceOf(self))
    return True

