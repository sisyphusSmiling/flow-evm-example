import "FungibleToken"

import "EVM"

/// This contract demonstrates how a Cadence contract can orchestrate owner
/// action on an EVM contract from an encapsulated COA.
///
/// Throughout, you'll see how to interact with Flow EVM from within a Cadence
///  contract, namely:
///     - Encoding & decoding ABI data
///     - Making calls to EVM contracts
///     - Deploying an EVM contract from a COA
///     - Handling call results to EVM contracts
///     - Decoding EVM call return values
///
/// By leveraging Cadence's native secure randomness, we can commit these
/// random values into FlowEVM, even conditioning public methods on state in
/// Flow EVM. This lends a differing security model to the notion of an "owned"
/// contract in EVM as the EVM contract is technically owned by a Cadence
/// contract.
///
access(all)
contract SimpleLotteryVRF {
    
    /// The EVM address of the deployed SimpleLottery contract
    access(all)
    let lotteryContractAddress: EVM.EVMAddress
    /// The CadenceOwnedAccount that will deploy and interact with the EVM
    /// lottery contract
    access(self)
    let coa: @EVM.CadenceOwnedAccount

    /// Event emitted when the lottery is complete
    access(all)
    event SimpleLotteryComplete(winner: EVM.EVMAddress, amount: UFix64)

    /// Get the EVM address of this contract's COA
    access(all)
    view fun getCOAEVMAddress(): EVM.EVMAddress {
        return self.coa.address()
    }

    /// Ends the lottery ongoing in the EVM contract by requesting a random
    /// number from Cadence runtime and passing that value as the random seed
    /// to the EVM contract. This is publicly accessible, so anyone can call
    /// this method, enabling a trustless lottery.
    ///
    access(all)
    fun resolve() {
        // Assert that the round is ready to be resolved
        assert(self.isReadyToResolve(), message: "Round is not yet over.")
        // Request a random number from Cadence runtime
        let randomSeed: UInt64 = revertibleRandom<UInt64>()
        // Endode the calldata
        let calldata: [UInt8] = EVM.encodeABIWithSignature(
            "resolve(uint64)",
            [randomSeed]
        )
        // Execute call to the SimpleLottery contract
        let result: EVM.Result = self.coa.call(
            to: self.lotteryContractAddress,
            data: calldata,
            gasLimit: 60000,
            value: EVM.Balance(attoflow: 0)
        )
        assert(result.status == EVM.Status.successful, message: "Call failed.")
        // Decode the return values
        let resultValues = EVM.decodeABI(
            types: [Type<EVM.EVMAddress>(), Type<UInt256>()],
            data: result.data
        ) as [AnyStruct]
        let winner = resultValues[0] as! EVM.EVMAddress
        let rawAmount = resultValues[1] as! UInt256
        // Convert the winning amount to UFix64
        let amount = EVM.Balance(attoflow: rawAmount).inFLOW()

        emit SimpleLotteryComplete(winner: winner, amount: amount)
    }

    /// Returns whether the lottery round is over and ready to end
    ///
    access(all)
    fun isReadyToResolve(): Bool {
        let calldata: [UInt8] = EVM.encodeABIWithSignature(
            "isReadyToResolve()",
            []
        )
        let result: EVM.Result = self.coa.call(
            to: self.lotteryContractAddress,
            data: calldata,
            gasLimit: 60000,
            value: EVM.Balance(attoflow: 0)
        )
        assert(result.status == EVM.Status.successful, message: "Call failed.")
        let resultValues = EVM.decodeABI(
            types: [Type<Bool>()],
            data: result.data
        ) as [AnyStruct]
        return resultValues[0] as! Bool
    }

    init() {
        // SimpleLottery compiled bytecode object
        let bytecode: String = ""
        // Create a new CadenceOwnedAccount and assign to this contract
        self.coa = EVM.createCadenceOwnedAccount()

        // Fund the COA with some initial balance from the deployment account's
        // FlowToken Vault
        let fundVault = self.account.storage
            .borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(
                from: /storage/flowTokenVault
            ) ?? panic("Could not borrow FlowToken Vault")
        self.coa.deposit(
            from: fundVault.withdraw(amount: 10.0)
        )

        // Deploy the EVM SimpleLottery contract & preserve the deployment
        // address
        self.lotteryContractAddress = self.coa.deploy(
            code: bytecode,
            gasLimit: 60000,
            value: EVM.Balance(attoflow: 0)
        )
    }
}
