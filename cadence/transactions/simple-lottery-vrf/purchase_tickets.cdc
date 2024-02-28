import "FungibleToken"
import "FlowToken"

import "EVM"

import "SimpleLotteryTicketVRF"

/// This transaction demonstrates how to make an EVM call from Cadence to an EVM contract. Assumes the signer's COA
/// is already set up and is funded with FLOW.
///
transaction(numTickets: UInt256, gasLimit: UInt64) {
    // A reference to the signer's COA used to execute the call
    let coa: auth(EVM.Call) &EVM.CadenceOwnedAccount
    let value: EVM.Balance

    prepare(signer: auth(PublishCapability, StorageCapabilities, Storage) &Account) {
        // Configure a COA in the signer's account if needed
        if signer.storage.type(at: /storage/evm) == nil {
            signer.storage.save(<-EVM.createCadenceOwnedAccount(), to: /storage/evm)
            let addressable = signer.capabilities.issue<&EVM.CadenceOwnedAccount>(/storage/evm)
            signer.capabilities.unpublish(/public/evm)
            signer.capabilities.publish(addressable, at: /public/evm)
        }
        // Borrow a reference to the signer's COA
        self.coa = signer.storage.borrow<auth(EVM.Call) &EVM.CadenceOwnedAccount>(
                from: /storage/evm
            ) ?? panic("This account is not configured with a COA.")

        // Set the value I will transmit with the purchaseTickets call
        self.value = EVM.Balance(attoflow: 0)
        assert(numTickets <= UInt256(UFix64.max), message: "Cannot convert numTickets to UFix64.")
        self.value.setFLOW(flow: UFix64(numTickets))

        // Send $FLOW to EVM if necessary, funding from signer's Cadence FlowToken Vault
        if self.coa.balance().inFLOW() < self.value.inFLOW() {
            let flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(
                    from: /storage/flowTokenVault
                ) ?? panic("Problem retrieving FlowToken Vault.")
            let fundVault <- flowVault.withdraw(amount: self.value.inFLOW() - self.coa.balance().inFLOW() + 0.001)
            self.coa.deposit(from: <-fundVault)
        }
    }

    execute {
        // Encode the known function signature and parameters for the purchaseTickets call
        let calldata: [UInt8] = EVM.encodeABIWithSignature(
            "purchaseTickets(UInt256)",
            [numTickets]
        )
        // Execute the call to the lottery contract
        let result: EVM.Result = self.coa.call(
            to: SimpleLotteryTicketVRF.lotteryContractAddress,
            data: calldata,
            gasLimit: gasLimit,
            value: self.value
        )
        // Ensure the call was successful
        assert(result.status == EVM.Status.successful, message: "EVM call failed.")
    }
}