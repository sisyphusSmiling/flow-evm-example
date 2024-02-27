## Flow EVM Example

Welcome to Flow EVM! This is an example project to help you get started working with Flow EVM using familiar EVM tooling
as well as interacting with EVM from the Cadence environment

## Overview

In this example, we're going to a set of smart contracts that codify a simple onchain lottery. The lottery "admin" will
be `CadenceOwnedAccount` (COA) which resides in a Cadence contract. This Cadence contract will have a single public
method that enables committment of a verifiably random number retrieved from the Cadence execution environment to the
lottery contract running in EVM.

Throughout this example, you'll learn how to:
- Deploy a Cadence contract
- Deploy an EVM contract using a `CadenceOwnedAccount`
- Query EVM state from Cadence
- Conditionally execute EVM state change from Cadence
- Orchestrate arbitrary calls to EVM from the Cadence runtime

### Pre-requisites

You'll need Foundry to interact with Flow EVM from the CLI as well as Flow CLI to interact with the Flow blockchain.

- [Flow CLI installation](https://developers.flow.com/tools/flow-cli/install)
- [Foundry installation](https://book.getfoundry.sh/getting-started/installation)

