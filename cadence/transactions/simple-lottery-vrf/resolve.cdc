import "SimpleLotteryVRF"

transaction {

    prepare(acct: &Account) {
    }

    execute {
        let lottery = SimpleLotteryVRF()
        lottery.withdraw()
    }
}