import { BigNumber as BN, constants } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

const Decimals = BN.from(18);
const OneToken = BN.from(10).pow(Decimals);

import {
  EscrowByAgent,
  EscrowByAgent__factory,
  MockERC20,
  MockERC20__factory,
} from "../typechain-types";

describe("Test EscrowByAgent contract: ", () => {
  let owner: SignerWithAddress;
  let sender1: SignerWithAddress;
  let recipient1: SignerWithAddress;
  let agent1: SignerWithAddress;
  let sender2: SignerWithAddress;
  let recipient2: SignerWithAddress;
  let agent2: SignerWithAddress;

  let aToken: MockERC20;
  let bToken: MockERC20;
  let escrow: EscrowByAgent;

  let poolCount: number;
  let poolId: number;

  const ethAmount = OneToken.mul(10);
  const amount = OneToken.mul(2000);
  const cancelLockDays = 5;
  const ownerFeePercent = 5;
  const agentFeePercent = 5;

  before(async () => {
    [owner, sender1, recipient1, agent1, sender2, recipient2, agent2] =
      await ethers.getSigners();
  });

  async function createPoolWithERC20Token() {
    // approve
    await aToken.connect(sender2).approve(escrow.address, amount);
    await escrow
      .connect(sender2)
      .deposit(aToken.address, recipient2.address, agent2.address, amount);

    await updatePoolId();
  }

  async function createPoolWithETH() {
    const option = { value: ethAmount };
    await escrow
      .connect(sender1)
      .depositByETH(recipient1.address, agent1.address, option);

    await updatePoolId();
  }

  async function releasePool(caller: SignerWithAddress, poolId: number) {
    await escrow.connect(caller).release(poolId);
  }

  async function cancelPool(caller: SignerWithAddress, poolId: number) {
    await escrow.connect(recipient2).approveCancel(poolId);
    await escrow.connect(sender2).approveCancel(poolId);
    await escrow.connect(caller).cancel(poolId);
  }

  async function updatePoolId() {
    poolCount = (await escrow.poolCount()).toNumber();
    poolId = poolCount - 1;
  }

  describe("1. Deploy contracts", () => {
    it("Deploy mock contracts", async () => {
      const erc20Factory = new MockERC20__factory(owner);
      aToken = await erc20Factory.deploy("A Token", "A");
      bToken = await erc20Factory.deploy("B Token", "B");
    });

    it("Deploy main contracts", async () => {
      const escrowByAgentFactory = new EscrowByAgent__factory(owner);
      escrow = await escrowByAgentFactory.deploy(
        ownerFeePercent * 100,
        agentFeePercent * 100,
        cancelLockDays
      );
    });
  });

  describe("2. Token transfer", () => {
    it("transfer tokens mock contracts", async () => {
      await aToken.transfer(sender1.address, OneToken.mul(1000000));
      await bToken.transfer(sender1.address, OneToken.mul(2000000));
      await aToken.transfer(sender2.address, OneToken.mul(1000000));
      await bToken.transfer(sender2.address, OneToken.mul(2000000));
    });
  });

  describe("3. Function unit test: ", () => {
    describe("- deployByETH function: ", () => {
      it("recipient address is invalid: zero address", async () => {
        const ethAmount = OneToken.mul(10);
        const option = { value: ethAmount };
        await expect(
          escrow
            .connect(sender1)
            .depositByETH(constants.AddressZero, agent1.address, option)
        ).to.be.revertedWith("address invalid");
      });

      it("agent address is invalid: zero address", async () => {
        const ethAmount = OneToken.mul(10);
        const option = { value: ethAmount };
        await expect(
          escrow
            .connect(sender1)
            .depositByETH(recipient1.address, constants.AddressZero, option)
        ).to.be.revertedWith("address invalid");
      });

      it("amount is invalid: zero", async () => {
        const ethAmount = OneToken.mul(0);
        const option = { value: ethAmount };
        await expect(
          escrow
            .connect(sender1)
            .depositByETH(recipient1.address, agent1.address, option)
        ).to.be.revertedWith("amount invalid");
      });

      it("address is invalid: same", async () => {
        const ethAmount = OneToken.mul(10);
        const option = { value: ethAmount };
        expect(
          escrow
            .connect(sender1)
            .depositByETH(recipient1.address, recipient1.address, option)
        ).to.be.revertedWith("address invalid: same");
        expect(
          escrow
            .connect(sender1)
            .depositByETH(sender1.address, agent1.address, option)
        ).to.be.revertedWith("address invalid: same");
        expect(
          escrow
            .connect(sender1)
            .depositByETH(recipient1.address, sender1.address, option)
        ).to.be.revertedWith("address invalid: same");
      });

      it("depositByETH success !!!", async () => {
        await createPoolWithETH();

        const pool = await escrow.pools(poolId);

        // check poolInfo
        expect(pool.token).to.be.equal(constants.AddressZero);
        expect(pool.sender).to.be.equal(sender1.address);
        expect(pool.recipient).to.be.equal(recipient1.address);
        expect(pool.agent).to.be.equal(agent1.address);
        expect(pool.isReleased).to.be.equal(false);
        expect(pool.amount).to.be.equal(ethAmount);
      });
    });

    describe("- deposit function: ", () => {
      it("recipient address is invalid: zero address", async () => {
        const amount = OneToken.mul(1000);
        await expect(
          escrow
            .connect(sender2)
            .deposit(
              aToken.address,
              constants.AddressZero,
              agent2.address,
              amount
            )
        ).to.be.revertedWith("address invalid");
      });

      it("agent address is invalid: zero address", async () => {
        const amount = OneToken.mul(1000);
        await expect(
          escrow
            .connect(sender2)
            .deposit(
              aToken.address,
              recipient2.address,
              constants.AddressZero,
              amount
            )
        ).to.be.revertedWith("address invalid");
      });

      it("amount is invalid: zero", async () => {
        const amount = OneToken.mul(0);
        await expect(
          escrow
            .connect(sender2)
            .deposit(aToken.address, recipient2.address, agent2.address, amount)
        ).to.be.revertedWith("amount invalid");
      });

      it("address is invalid: same", async () => {
        const amount = OneToken.mul(1000);
        expect(
          escrow
            .connect(sender2)
            .deposit(
              bToken.address,
              recipient2.address,
              recipient2.address,
              amount
            )
        ).to.be.revertedWith("address invalid: same");
        expect(
          escrow
            .connect(sender2)
            .deposit(bToken.address, sender2.address, agent2.address, amount)
        ).to.be.revertedWith("address invalid: same");
        expect(
          escrow
            .connect(sender2)
            .deposit(
              bToken.address,
              recipient2.address,
              sender2.address,
              amount
            )
        ).to.be.revertedWith("address invalid: same");
      });

      it("ERC20: insufficient allowance", async () => {
        const amount = OneToken.mul(1000);
        await expect(
          escrow
            .connect(sender2)
            .deposit(
              aToken.address,
              recipient2.address,
              recipient2.address,
              amount
            )
        ).to.be.revertedWith("ERC20: insufficient allowance");
      });

      it("deposit success !!!", async () => {
        await createPoolWithERC20Token();

        const pool = await escrow.pools(poolId);

        // check poolInfo
        expect(pool.token).to.be.equal(aToken.address);
        expect(pool.sender).to.be.equal(sender2.address);
        expect(pool.recipient).to.be.equal(recipient2.address);
        expect(pool.agent).to.be.equal(agent2.address);
        expect(pool.isReleased).to.be.equal(false);
        expect(pool.amount).to.be.equal(amount);
      });
    });

    describe("- approveCancel function: ", () => {
      before(async () => {
        await createPoolWithERC20Token();
      });

      it("poolId invalid", async () => {
        await expect(
          escrow.connect(sender2).approveCancel(poolCount)
        ).to.be.revertedWith("poolId invalid");
      });

      it("no permission", async () => {
        await expect(
          escrow.connect(sender1).approveCancel(poolId)
        ).to.be.revertedWith("no permission");
      });

      it("approveCancel success: sender !!!", async () => {
        await escrow.connect(sender2).approveCancel(poolId);

        expect(
          escrow.connect(sender2).approveCancel(poolId)
        ).to.be.revertedWith("already done");
      });

      it("approveCancel success: agent !!!", async () => {
        await escrow.connect(agent2).approveCancel(poolId);

        expect(escrow.connect(agent2).approveCancel(poolId)).to.be.revertedWith(
          "already done"
        );
      });

      it("approveCancel success: recipient !!!", async () => {
        await escrow.connect(recipient2).approveCancel(poolId);

        expect(
          escrow.connect(recipient2).approveCancel(poolId)
        ).to.be.revertedWith("already done");
      });
    });

    describe("- cancelable function: ", () => {
      before(async () => {
        await createPoolWithERC20Token();
      });

      it("poolId invalid", async () => {
        await expect(
          await escrow.connect(sender2).cancelable(poolCount)
        ).to.be.equal(false);
      });

      it("nobody of recipient and agent didn't approve", async () => {
        await expect(
          await escrow.connect(sender2).cancelable(poolId)
        ).to.be.equal(false);
      });

      it("caller is not sender of pool and sender didn't approve yet", async () => {
        await createPoolWithERC20Token();
        await escrow.connect(recipient2).approveCancel(poolId);
        await expect(
          await escrow.connect(sender1).cancelable(poolId)
        ).to.be.equal(false);
      });

      it("agent approved and sender approved, but this is during cancelLockTime", async () => {
        await createPoolWithERC20Token();
        await escrow.connect(agent2).approveCancel(poolId);
        await escrow.connect(sender2).approveCancel(poolId);
        await expect(
          await escrow.connect(sender1).cancelable(poolId)
        ).to.be.equal(false);
      });

      it("agent approved && sender approved && this is after cancelLockTime, but already cancel or released", async () => {
        await createPoolWithERC20Token();
        await escrow.connect(agent2).approveCancel(poolId);
        await escrow.connect(sender2).approveCancel(poolId);

        await ethers.provider.send("evm_increaseTime", [
          cancelLockDays * 24 * 3600 + 1,
        ]);

        await releasePool(agent2, poolId);

        await expect(
          await escrow.connect(sender1).cancelable(poolId)
        ).to.be.equal(false);

        // create a new pool
        await createPoolWithERC20Token();
        await ethers.provider.send("evm_increaseTime", [
          cancelLockDays * 24 * 3600 + 1,
        ]);
        await cancelPool(sender1, poolId);

        await expect(
          await escrow.connect(sender1).cancelable(poolId)
        ).to.be.equal(false);
      });
    });

    describe("- cancel function: ", () => {
      before(async () => {
        await createPoolWithERC20Token();
      });

      it("poolId invalid", async () => {
        await expect(
          escrow.connect(sender2).cancel(poolCount)
        ).to.be.revertedWith("poolId invalid");
      });

      it("nobody of recipient and agent didn't approve", async () => {
        await expect(escrow.connect(sender2).cancel(poolId)).to.be.revertedWith(
          "can't cancel"
        );
      });

      it("caller is not sender of pool and sender didn't approve yet", async () => {
        await createPoolWithERC20Token();
        await escrow.connect(recipient2).approveCancel(poolId);
        await expect(escrow.connect(sender1).cancel(poolId)).to.be.revertedWith(
          "sender didn't approve"
        );
      });

      it("agent approved and sender approved, but this is during cancelLockTime", async () => {
        await createPoolWithERC20Token();
        await escrow.connect(agent2).approveCancel(poolId);
        await escrow.connect(sender2).approveCancel(poolId);
        await expect(escrow.connect(sender1).cancel(poolId)).to.be.revertedWith(
          "during cancelLock"
        );
      });

      it("agent approved && sender approved && this is after cancelLockTime, but already cancel or released", async () => {
        await createPoolWithERC20Token();
        await escrow.connect(agent2).approveCancel(poolId);
        await escrow.connect(sender2).approveCancel(poolId);

        await ethers.provider.send("evm_increaseTime", [5 * 24 * 60 * 60 + 1]);

        await releasePool(agent2, poolId);

        await expect(escrow.connect(sender1).cancel(poolId)).to.be.revertedWith(
          "no money in pool"
        );

        // create a new pool
        await createPoolWithERC20Token();
        await ethers.provider.send("evm_increaseTime", [5 * 24 * 60 * 60 + 1]);
        await cancelPool(sender1, poolId);

        await expect(escrow.connect(sender1).cancel(poolId)).to.be.revertedWith(
          "no money in pool"
        );
      });

      it("cancel success: ERC20 token (A token) !!!", async () => {
        const balanceOfSender = await aToken.balanceOf(sender2.address);
        await createPoolWithERC20Token();
        await cancelPool(sender1, poolId);

        const balanceOfSender_2 = await aToken.balanceOf(sender2.address);
        expect(balanceOfSender_2).to.be.equal(balanceOfSender);
      });
    });

    describe("- release function: ", () => {
      before(async () => {
        await createPoolWithERC20Token();
      });

      it("caller invalid: not agent", async () => {
        await expect(
          escrow.connect(sender2).release(poolId)
        ).to.be.revertedWith("not agent");
      });

      it("no money in pool", async () => {
        await cancelPool(sender1, poolId);
        await expect(escrow.connect(agent2).release(poolId)).to.be.revertedWith(
          "no money in pool"
        );
      });

      it("already released", async () => {
        await createPoolWithERC20Token();
        await releasePool(agent2, poolId);
        await expect(escrow.connect(agent2).release(poolId)).to.be.revertedWith(
          "already released"
        );
      });

      it("eth release success !!!", async () => {
        const balanceOfOwner = await ethers.provider.getBalance(owner.address);
        const balanceOfAgent = await ethers.provider.getBalance(agent1.address);
        const balanceOfRecipient = await ethers.provider.getBalance(
          recipient1.address
        );

        const transaction = await escrow.connect(agent1).release(0);
        const receipt = await transaction.wait();

        const pool = await escrow.pools(0);

        // check poolInfo
        expect(pool.token).to.be.equal(constants.AddressZero);
        expect(pool.sender).to.be.equal(sender1.address);
        expect(pool.recipient).to.be.equal(recipient1.address);
        expect(pool.agent).to.be.equal(agent1.address);
        expect(pool.isReleased).to.be.equal(true);
        expect(pool.amount).to.be.equal(ethAmount);

        // check balance
        const balanceOfOwner_2 = await ethers.provider.getBalance(
          owner.address
        );
        const balanceOfAgent_2 = await ethers.provider.getBalance(
          agent1.address
        );
        const balanceOfRecipient_2 = await ethers.provider.getBalance(
          recipient1.address
        );

        expect(balanceOfOwner_2.sub(balanceOfOwner)).to.be.equal(
          ethAmount.mul(ownerFeePercent).div(100)
        );
        expect(balanceOfAgent_2.sub(balanceOfAgent)).to.be.equal(
          ethAmount
            .mul(agentFeePercent)
            .div(100)
            .sub(receipt.gasUsed.mul(receipt.effectiveGasPrice))
        );
        expect(balanceOfRecipient_2.sub(balanceOfRecipient)).to.be.equal(
          ethAmount.mul(90).div(100)
        );
      });

      it("ERC20 token (A token) release success !!!", async () => {
        const balanceOfOwner = await aToken.balanceOf(owner.address);
        const balanceOfAgent = await aToken.balanceOf(agent2.address);
        const balanceOfRecipient = await aToken.balanceOf(recipient2.address);

        const transaction = await escrow.connect(agent2).release(1);
        await transaction.wait();

        await updatePoolId();

        const pool = await escrow.pools(poolId);

        // check poolInfo
        expect(pool.token).to.be.equal(aToken.address);
        expect(pool.sender).to.be.equal(sender2.address);
        expect(pool.recipient).to.be.equal(recipient2.address);
        expect(pool.agent).to.be.equal(agent2.address);
        expect(pool.isReleased).to.be.equal(true);
        expect(pool.amount).to.be.equal(amount);

        // check balance
        const balanceOfOwner_2 = await aToken.balanceOf(owner.address);
        const balanceOfAgent_2 = await aToken.balanceOf(agent2.address);
        const balanceOfRecipient_2 = await aToken.balanceOf(recipient2.address);

        expect(balanceOfOwner_2.sub(balanceOfOwner)).to.be.equal(
          amount.mul(ownerFeePercent).div(100)
        );
        expect(balanceOfAgent_2.sub(balanceOfAgent)).to.be.equal(
          amount.mul(agentFeePercent).div(100)
        );
        expect(balanceOfRecipient_2.sub(balanceOfRecipient)).to.be.equal(
          amount.mul(90).div(100)
        );
      });
    });
  });
});
