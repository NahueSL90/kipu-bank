    // SPDX-License-Identifier: MIT
    pragma solidity 0.8.26;

    /**
    * @title KipuBank - Trabajo Práctico Nº2 (ETH KIPU)
    * @author NahuelSL90
    * @notice Contrato educativo que simula un banco digital para depósitos y retiros en ETH, con ciertos parametros.
    * @dev No debe usarse en producción. Incluye medidas básicas contra reentrancy y límites diarios.
    */
    contract KipuBank {
        /*///////////////////////////////////
                        STATE VARIABLES
        ///////////////////////////////////*/

        /// @notice Límite máximo de retiro por usuario (por día).
        /// @dev se despliega en el constructor para que el contrato sea mas flexible y dinamico.
        uint256 private immutable i_userWithdrawLimit;

        /// @notice Tiempo de espera (cooldown) entre reinicios del contador diario
        uint256 private constant COOLDOWN = 1 days;

        /// @notice Máximo de ETH permitido en el vault
        uint256 private immutable i_bankCap;

        /// @notice Total de ETH depositados en el contrato
        uint256 public s_totalDeposits;

        /// @notice Total global de depósitos realizados
        uint256 public s_totalDepositCount;

        /// @notice Total global de retiros realizados
        uint256 public s_totalWithdrawCount;

        /// @notice Estado interno del lock anti-reentrancy
        bool private locked;

        /// @notice Estructura que almacena la información de cada usuario para posteriormente arrojarla en getUserData.
        struct UserData {
            uint256 totalDeposited;
            uint256 lastWithdrawal;
            uint256 withdrawnToday;
            uint256 depositCount;
            uint256 withdrawCount;
        }

        /// @notice Registro de datos por dirección de usuario
        mapping(address => UserData) private s_users;

        /*///////////////////////////////////
                        EVENTS
        ///////////////////////////////////*/

        /// @notice Se emite cuando un depósito se procesa correctamente en la funcion Deposit.
        event Message_DepositProcessed(
            address indexed sender,
            uint256 amount,
            uint256 totalDeposited
        );

        /// @notice Se emite cuando un retiro se procesa correctamente en la funcion withdraw.
        event Message_WithdrawProcessed(
            address indexed user,
            uint256 amount,
            uint256 timestamp
        );

        /*///////////////////////////////////
                        ERRORS
        ///////////////////////////////////*/

        /// @notice Se emite cel error cuando falla algun parametro asignado en los modificadores. Interactua tanto en la funcion Deposit como en Withdraw.
        error Deposit_MaxCapReached();
        error Deposit_Zero();
        error Withdraw_NotDepositor();
        error Withdraw_ExceededLimit();
        error Withdraw_InsufficientBalance();

        /*///////////////////////////////////
                        MODIFIERS
        ///////////////////////////////////*/

        /**
        * @notice Verifica las condiciones necesarias para aceptar un depósito.
        * @dev Rechaza depósitos de 0 ETH o que superen el máximo del vault.
        */
        modifier validDeposit() {
            if (msg.value == 0) revert Deposit_Zero();
            if (s_totalDeposits + msg.value > i_bankCap)
                revert Deposit_MaxCapReached();
            _;
        }

        /**
        * @notice Controla ciertos parametros para que el usuario pueda retirar fondos.
        * @dev Previene reentrancy, verifica cooldown, límite diario (1 eth por dia) y balance.
        * @param _amount Cantidad en wei que se desea retirar.
        */
        modifier canWithdraw(uint256 _amount) {
            require(!locked, "Reentrancy detected");
            locked = true;

            UserData storage user = s_users[msg.sender];

            if (user.totalDeposited == 0) revert Withdraw_NotDepositor();
            if (_amount == 0) revert Withdraw_ExceededLimit();
            if (_amount > user.totalDeposited)
                revert Withdraw_InsufficientBalance();

            // Reiniciar contador diario si pasó el cooldown
            if (block.timestamp > user.lastWithdrawal + COOLDOWN) {
                user.withdrawnToday = 0;
                user.lastWithdrawal = block.timestamp;
            }

            // Límite diario de retiro (máx i_userWithdrawLimit (1 eth cada 24 horas))
            if (user.withdrawnToday + _amount > i_userWithdrawLimit)
                revert Withdraw_ExceededLimit();

            _;

            // Actualización de saldos antes del retiro retiro
            unchecked {
                user.withdrawnToday += _amount;
                user.lastWithdrawal = block.timestamp;
            }

            locked = false;
        }

        /*///////////////////////////////////
                        FUNCTIONS
        ///////////////////////////////////*/

        /**
        * @notice Permite al usuario depositar ETH al contrato.
        * @dev Llama al modifier `validDeposit` para verificar límites.
        */
        function deposit() external payable validDeposit {
            UserData storage user = s_users[msg.sender];

            unchecked {
                s_totalDeposits += msg.value;
                user.totalDeposited += msg.value;
                ++s_totalDepositCount;
                ++user.depositCount;
            }

            emit Message_DepositProcessed(msg.sender, msg.value, s_totalDeposits);
        }

        /**
        * @notice Permite retirar ETH, con un máximo diario definido en el constructor.
        * @param _amount Cantidad en wei a retirar.
        */
        function withdraw(uint256 _amount) external canWithdraw(_amount) {
            UserData storage user = s_users[msg.sender];

            unchecked {
                user.totalDeposited -= _amount;
                s_totalDeposits -= _amount;
                ++s_totalWithdrawCount;
                ++user.withdrawCount;
            }

            _ethTransfer(payable(msg.sender), _amount);
            emit Message_WithdrawProcessed(msg.sender, _amount, block.timestamp);
        }

        /**
        * @notice Realiza una transferencia segura de ETH.
        * @dev Usa "call" para evitar problemas de límite de gas. Se indica que la wallet de retiro es payable 
                para que admita el envio de ETH
        */
        function _ethTransfer(address payable _to, uint256 _amount) internal {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "ETH transfer failed");
        }

        /**
        * @notice Retorna el balance actual del contrato.
        * @return balance del contrato en wei.
        */
        function getBalance() external view returns (uint256 balance) {
            return address(this).balance;
        }

        /**
        * @notice Retorna información detallada del historial transaccional del usuario.
        * @param _user Dirección del usuario a consultar.
        * @return deposited Total depositado.
        * @return withdrawnToday Total retirado hoy.
        * @return lastWithdrawal Último retiro (timestamp).
        * @return depositCount Número de depósitos.
        * @return withdrawCount Número de retiros.
        */
        function getUserData(
            address _user
        )
            external
            view
            returns (
                uint256 deposited,
                uint256 withdrawnToday,
                uint256 lastWithdrawal,
                uint256 depositCount,
                uint256 withdrawCount
            )
        {
            UserData memory data = s_users[_user];
            return (
                data.totalDeposited,
                data.withdrawnToday,
                data.lastWithdrawal,
                data.depositCount,
                data.withdrawCount
            );
        }

        /**
        * @notice Retorna estadísticas globales del vault.
        * @return totalDeposits Total ETH depositado.
        * @return totalDepositCount Total de depósitos realizados.
        * @return totalWithdrawCount Total de retiros realizados.
        * @return maxCap Capacidad máxima del vault.
        * @return contractBalance Balance actual del contrato.
        * @return withdrawLimit Límite diario de retiro por usuario.
        */
        function getVaultStats()
            external
            view
            returns (
                uint256 totalDeposits,
                uint256 totalDepositCount,
                uint256 totalWithdrawCount,
                uint256 maxCap,
                uint256 contractBalance,
                uint256 withdrawLimit
            )
        {
            return (
                s_totalDeposits,
                s_totalDepositCount,
                s_totalWithdrawCount,
                i_bankCap,
                address(this).balance,
                i_userWithdrawLimit
            );
        }

        /*///////////////////////////////////
                        CONSTRUCTOR
        ///////////////////////////////////*/

        /**
        * @notice Inicializa el contrato con un máximo total permitido de ETH y el límite de retiro diario.
        * @param _maxCap Valor máximo del vault (10 eth medidos en wei).
        * @param _withdrawLimit Límite diario por usuario (1 eth medido en wei).
        */
        constructor(uint256 _maxCap, uint256 _withdrawLimit) {
            require(_maxCap > 0, "Max cap must be > 0");
            require(_withdrawLimit > 0, "Withdraw limit must be > 0");
            i_bankCap = _maxCap;
            i_userWithdrawLimit = _withdrawLimit;
        }

        /*///////////////////////////////////
                    RECEIVE & FALLBACK
        ///////////////////////////////////*/

        /// @notice Evita depósitos directos sin usar la función deposit()
        receive() external payable {
            revert("Use the deposit() function");
        }
        /// @notice Evita llamadas a funciones inexistentes
        fallback() external payable {
            revert("Function does not exist");
        }
    }
