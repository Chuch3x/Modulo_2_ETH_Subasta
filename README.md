# 🎯 Auction Smart Contract

Este repositorio contiene el contrato inteligente `Auction.sol`, desarrollado como parte del **Trabajo Final - Módulo 2** del curso de Blockchain. El contrato representa una subasta desplegada en la red **Et (11155111)hereum Testnet Sepolia**.

---

## 📦 Características

- Subasta de un ítem con pujas en ETH.
- Las ofertas deben superar en **al menos un 5%** a la anterior.
- Extensión automática de la subasta si se puja en los últimos **10 minutos**.
- Gestión segura de **depósitos pendientes**.
- Emisión de **eventos** (nueva oferta, finalización de subasta).
- Recuperación de fondos para oferentes no ganadores.
- Cálculo y envío de comisión del 2% al finalizar.

---

## 🛠 Constructor

constructor(
address \_benefactor,
string memory \_name,
string memory \_description,
uint256 durationInSeconds
)
