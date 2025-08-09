module VaultStrategy::YieldOptimizer {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    struct VaultStrategy has store, key {
        total_deposited: u64,    
        yield_rate: u64,          
        last_yield_time: u64,     
        strategy_active: bool,   
        min_deposit: u64,         
    }
    struct UserDeposit has store, key, drop {
        amount: u64,              
        deposit_time: u64,      
        earned_yield: u64,        
    }

    public fun create_vault_strategy(
        owner: &signer, 
        yield_rate: u64, 
        min_deposit: u64
    ) {
        let vault_strategy = VaultStrategy {
            total_deposited: 0,
            yield_rate,
            last_yield_time: timestamp::now_seconds(),
            strategy_active: true,
            min_deposit,
        };
        move_to(owner, vault_strategy);
    }

    public fun deposit_to_vault(
        depositor: &signer, 
        vault_owner: address, 
        amount: u64
    ) acquires VaultStrategy {
        let vault = borrow_global_mut<VaultStrategy>(vault_owner);
        
        assert!(vault.strategy_active, 1);
        assert!(amount >= vault.min_deposit, 2);
        
        let deposit_coins = coin::withdraw<AptosCoin>(depositor, amount);
        coin::deposit<AptosCoin>(vault_owner, deposit_coins);
        
        vault.total_deposited = vault.total_deposited + amount;
        
        let user_deposit = UserDeposit {
            amount,
            deposit_time: timestamp::now_seconds(),
            earned_yield: 0,
        };
        
        let depositor_addr = signer::address_of(depositor);
        if (!exists<UserDeposit>(depositor_addr)) {
            move_to(depositor, user_deposit);
        };
    }

}
