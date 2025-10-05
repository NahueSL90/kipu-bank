# Kipu-Bank

## Descripción

KipuBank es un contrato educativo que simula un banco digital en Ethereum.  
Permite a los usuarios depositar y retirar ETH, con ciertos parametros tanto al depositar, como al retirar.
Incluye medidas básicas de seguridad, como prevención de reentrancy y límite diario de retiro.

---------------------------

## Despliegue

1. Clonar el repositorio desde mi repositorio:

2. Ir a Remix, crear una nueva carpeta con el nombre que deseas. Dentro de dicha carpeta, crear un file contrats.sol y pegar el contrato en su totalidad.

3. Una vez realizado el paso dos, guardar con "Ctrl + S" y seleccionar el compilador correcto en Remix, en este caso, el contrato se realizo con el compilador pragma solidity 0.8.26. Una vez seleccionado el compilador correcto, hacer click sobre el boton "Compile Contracts.Sol".

4. Realizado el paso anterior, dentro de Remix ir a la secciòn "Deploy and Run", seleccionar el enviroment "injected provider", asociar a tu billetera de metamask, la cual debe estar en la cadena "sepolia" y con fondos suficientes para hacer el deppy del contrato.

5. Una vez realizados los pasos anteriores, antes de realizar deploy, vas a tener que seleccionar los valores a asignar para las variable immutables, las cuales se encuentran declaradas en el compilador. En mi caso, seleccione como _maxCap 10 ETH expresados en wei y como _withdrawLimit 1 eth expresado en wei.

6. Asignados todos estos parametros, dar click sobre transfer (resaltado en color naranja).

7. Listo, contrato desplegado, unicamente resta verificar y publicar para darle transparencia al mismo y que sea opensource.


---------------------------

## Cómo interactuar con el contrato

Una vez desplegado (por ejemplo en Remix o Etherscan), podés interactuar con las siguientes funciones:


🔹 deposit() — external payable

Envía ETH al contrato.

Ingresá el monto en el campo Value (ejemplo: 0.5 ether).

Hacé clic en Transact para confirmar.

Se emite un evento Message_DepositProcessed al completarse.



🔹 withdraw(uint256 _amount) — external

Retira fondos del contrato (máx. 1 ETH cada 24h).

Ingresá el monto en wei (por ejemplo, 1000000000000000000 para 1 ETH).

Presioná Transact para ejecutar.

Si se cumplen las condiciones, se emite Message_WithdrawProcessed.



🔹 getUserData(address _user) — external view

Devuelve los datos del usuario:

Total depositado.

Total retirado hoy.

Último retiro (timestamp).

Cantidad de depósitos y retiros realizados.



🔹 getVaultStats() — external view

Muestra el estado global del contrato:

Total depositado.

Número de depósitos y retiros.

Capacidad máxima (i_bankCap).

Límite diario (i_userWithdrawLimit).

Balance actual.



📘 Tip:
Para probarlo fácilmente, usá Remix conectado a la red Sepolia Testnet con una cuenta que tenga ETH de prueba.
