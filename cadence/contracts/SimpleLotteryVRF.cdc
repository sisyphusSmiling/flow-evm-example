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
        // SimpleLottery compiled bytecode object - note we removed the 0x prefix
        let bytecode: String = "608060405234801561001057600080fd5b50338061003757604051631e4fbdf760e01b81526000600482015260240160405180910390fd5b61004081610060565b50670de0b6b3a76400006001556100584360646100b0565b6002556100d7565b600080546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b808201808211156100d157634e487b7160e01b600052601160045260246000fd5b92915050565b61098d806100e66000396000f3fe6080604052600436106100c25760003560e01c80638da5cb5b1161007f578063dfbf53ae11610059578063dfbf53ae1461023a578063eced428f1461025a578063f1151e761461026f578063f2fde38b1461028257600080fd5b80638da5cb5b146101c8578063b401faf1146101e6578063c8e583a6146101fb57600080fd5b8063083c6323146100c75780631209b1f6146100f057806312923b65146101065780632a44eda61461013e5780636ccda0a614610161578063715018a6146101b1575b600080fd5b3480156100d357600080fd5b506100dd60025481565b6040519081526020015b60405180910390f35b3480156100fc57600080fd5b506100dd60015481565b34801561011257600080fd5b5061012661012136600461082b565b6102a2565b6040516001600160a01b0390911681526020016100e7565b34801561014a57600080fd5b5060025443101560405190151581526020016100e7565b34801561016d57600080fd5b5061019861017c366004610844565b60056020526000908152604090205467ffffffffffffffff1681565b60405167ffffffffffffffff90911681526020016100e7565b3480156101bd57600080fd5b506101c66102cc565b005b3480156101d457600080fd5b506000546001600160a01b0316610126565b3480156101f257600080fd5b506101c66102e0565b34801561020757600080fd5b5061021b610216366004610874565b6103d1565b604080516001600160a01b0390931683526020830191909152016100e7565b34801561024657600080fd5b50600454610126906001600160a01b031681565b34801561026657600080fd5b506003546100dd565b6101c661027d366004610874565b61056d565b34801561028e57600080fd5b506101c661029d366004610844565b610740565b600381815481106102b257600080fd5b6000918252602090912001546001600160a01b0316905081565b6102d461077b565b6102de60006107a8565b565b6004546001600160a01b0316331461033f5760405162461bcd60e51b815260206004820181905260248201527f43616c6c6572206973206e6f7420746865206c6f74746572792077696e6e657260448201526064015b60405180910390fd5b604051600090339047908381818185875af1925050503d8060008114610381576040519150601f19603f3d011682016040523d82523d6000602084013e610386565b606091505b50509050806103ce5760405162461bcd60e51b81526020600482015260146024820152732330b4b632b2103a379039b2b73210232627ab9760611b6044820152606401610336565b50565b6000806103dc61077b565b60025443101561042e5760405162461bcd60e51b815260206004820152601e60248201527f43757272656e7420726f756e64206973206e6f7420796574206f7665722e00006044820152606401610336565b6004546001600160a01b03166104865760405162461bcd60e51b815260206004820152601f60248201527f57696e6e65722068617320616c7265616479206265656e207069636b65642e006044820152606401610336565b6003546000036104d1576040516000808252907fe5e0b77d021f0f1598b542e766f03a3a12d2895e1bb46e915b7b52368746d65c9060200160405180910390a2506000905080915091565b60006104e46000600380549050866107f8565b9050600381815481106104f9576104f961089e565b60009182526020918290200154600480546001600160a01b0319166001600160a01b03909216918217905560405147808252927fe5e0b77d021f0f1598b542e766f03a3a12d2895e1bb46e915b7b52368746d65c910160405180910390a26004546001600160a01b03169350915050915091565b60025443106105b65760405162461bcd60e51b81526020600482015260156024820152742a3434b9903637ba3a32b93c9034b99037bb32b91760591b6044820152606401610336565b60008167ffffffffffffffff161161061f5760405162461bcd60e51b815260206004820152602660248201527f596f75206d757374207075726368617365206174206c65617374206f6e65207460448201526534b1b5b2ba1760d11b6064820152608401610336565b6001546106369067ffffffffffffffff83166108ca565b3410156106855760405162461bcd60e51b815260206004820152601860248201527f496e73756666696369656e742066756e64732073656e742e00000000000000006044820152606401610336565b33600090815260056020526040812080548392906106ae90849067ffffffffffffffff166108e7565b92506101000a81548167ffffffffffffffff021916908367ffffffffffffffff16021790555060005b8167ffffffffffffffff168167ffffffffffffffff16101561073c5760038054600181810183556000929092527fc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b0180546001600160a01b03191633179055016106d7565b5050565b61074861077b565b6001600160a01b03811661077257604051631e4fbdf760e01b815260006004820152602401610336565b6103ce816107a8565b6000546001600160a01b031633146102de5760405163118cdaa760e01b8152336004820152602401610336565b600080546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b600083610805818561090f565b6108199067ffffffffffffffff8516610922565b6108239190610944565b949350505050565b60006020828403121561083d57600080fd5b5035919050565b60006020828403121561085657600080fd5b81356001600160a01b038116811461086d57600080fd5b9392505050565b60006020828403121561088657600080fd5b813567ffffffffffffffff8116811461086d57600080fd5b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b80820281158282048414176108e1576108e16108b4565b92915050565b67ffffffffffffffff818116838216019080821115610908576109086108b4565b5092915050565b818103818111156108e1576108e16108b4565b60008261093f57634e487b7160e01b600052601260045260246000fd5b500690565b808201808211156108e1576108e16108b456fea2646970667358221220040d680c301647599a05e36ef554d90a5ba842ce6cc149f0ab687c24873a905b64736f6c63430008170033"
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
