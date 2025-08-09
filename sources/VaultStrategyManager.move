module VaultStrategy::YieldOptimizer {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a yield optimization vault strategy
    struct VaultStrategy has store, key {
        total_deposited: u64,     // Total tokens deposited in the vault
        yield_rate: u64,          // Annual yield rate in basis points (e.g., 500 = 5%)
        last_yield_time: u64,     // Timestamp of last yield calculation
        strategy_active: bool,    // Whether the strategy is currently active
        min_deposit: u64,         // Minimum deposit amount required
    }

    /// Struct to track individual user deposits
    struct UserDeposit has store, key, drop {
        amount: u64,              // User's deposited amount
        deposit_time: u64,        // Timestamp when deposit was made
        earned_yield: u64,        // Accumulated yield earned
    }

    /// Function to create a new vault strategy
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

    /// Function for users to deposit tokens and participate in yield optimization
    public fun deposit_to_vault(
        depositor: &signer, 
        vault_owner: address, 
        amount: u64
    ) acquires VaultStrategy {
        let vault = borrow_global_mut<VaultStrategy>(vault_owner);
        
        // Check if strategy is active and meets minimum deposit
        assert!(vault.strategy_active, 1);
        assert!(amount >= vault.min_deposit, 2);
        
        // Transfer tokens from depositor to vault owner
        let deposit_coins = coin::withdraw<AptosCoin>(depositor, amount);
        coin::deposit<AptosCoin>(vault_owner, deposit_coins);
        
        // Update vault total
        vault.total_deposited = vault.total_deposited + amount;
        
        // Create or update user deposit record
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