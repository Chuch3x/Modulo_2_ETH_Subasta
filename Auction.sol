// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Auction {
    // Estructura del item que se subastara
    struct Item {
        string name;
        string description;
    }

    struct Bid {
        uint256 amount;
        uint256 timestamp;
    }

    // Errores del S.C
    error Auction__HighestBidderCantWithdraw();
    error Auction__NoPendingBids();
    error Auction__CantCompleteWithdraw();
    error Auction_NotEnded();
    error Auction_Ended();
    error Auction_AmmounShouldBeGreater();
    error Auction_CantCompleteSending();

    address payable immutable benefactor; // Ganador de la subasta
    address public highestBidder; // Subastador que va ganando
    uint256 public highestAmmountBidded; // Monto mas alto pujado
    uint256 public endTime; // Tiempo o fecha de finalizacion

    Item public item; 
    
    mapping (address => uint256) public pendingBids; // Pujas pendientes (Montos)
    mapping(address => Bid[]) public userBids; // historial de pujas [address -> monto|tiempo]
    address[] public bidders; // lista de todos los participantes
    mapping(address => bool) public alreadyBid; // para evitar duplicados en bidders[]

    // Eventos de la subasta
    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    // Constructor de la subasta
    constructor(address _benefactor, string memory _name, string memory _description, uint256 durationInSeconds){
        benefactor = payable(_benefactor);
        item = Item(_name, _description);
        endTime = block.timestamp + durationInSeconds;
    }

    // Permite ofertar por el ítem | Donde la oferta debe ser al menos 5% superior a la actual, y dentro del tiempo permitido
    function bid () payable external {
        require(block.timestamp < endTime, "Subasta finalizada"); // Verificamos que la subasta siga activa
        require(msg.value > highestAmmountBidded + (highestAmmountBidded * 5) / 100, "La oferta debe superar en %5"); // Verificamos que el monto ofertado sea mayor en un 5% al highestAmmountBidded

        if(highestBidder != address(0)){
            pendingBids[highestBidder] += highestAmmountBidded;
        }

         // Si una oferta válida se realiza dentro de los últimos 10 minutos, el plazo de la subasta se extiende 10 minutos más.
        if (endTime - block.timestamp <= 10 minutes) {
            endTime +=  10 minutes;
        }

        highestBidder = msg.sender;
        highestAmmountBidded = msg.value;

        userBids[msg.sender].push(Bid(msg.value, block.timestamp)); //Registramos la puja ofertada en el historial de pujas

        if (!alreadyBid[msg.sender]) {
            alreadyBid[msg.sender] = true;
            bidders.push(msg.sender);
        }

        emit NewBid(msg.sender, msg.value);
    }

    /// Retira depósitos pendientes si no fuiste el ganador
    function withdraw() external{
        // Verificar si tiene montos pendientes
        if(pendingBids[msg.sender] == 0) { // Es como un require pero la condicion invertida
            revert Auction__NoPendingBids();
        }

        uint256 ammountTosend = pendingBids[msg.sender];
        pendingBids[msg.sender] = 0;

        // Enviar montos pendientes
        (bool sent, ) = (msg.sender).call{value: ammountTosend}("");

        if (!sent) {
            revert Auction__CantCompleteWithdraw();
        }
    }

    // Finaliza la subasta y transfiere fondos al beneficiario menos la comisión del 2%
    function endAuction() external  {
        if( block.timestamp < endTime){
            revert Auction_NotEnded();
        }

        uint256 commission = (highestAmmountBidded * 2) / 100;
        uint256 amountToSend = highestAmmountBidded - commission;

        (bool sent, ) = benefactor.call{value: amountToSend}("");
         if (!sent) {
            revert Auction_CantCompleteSending();
        }
    }

     // Devuelve el ganador actual y su oferta
    function getWinner() external view returns (address, uint256) {
        return (highestBidder, highestAmmountBidded);
    }

    // Lista todos los oferentes
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // Verifica si la subasta aún está activa
    function isAuctionActive() external view returns (bool) {
        return block.timestamp < endTime;
    }

    // Devuelve el tiempo restante en segundos
    function timeLeft() external view returns (uint256) {
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }
}
