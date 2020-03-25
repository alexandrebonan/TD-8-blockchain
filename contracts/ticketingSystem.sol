pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;


contract  ticketingSystem{


  
    event NewArtist(uint artistId,bytes32 name,uint artistCategory);
    event ModifiedArtist(uint artistId,bytes32 name,uint artistCategory);

    mapping (address=>bool) public isAnArtist;
    
    struct Artist{
        address payable owner;
        bytes32 name;
        uint artistCategory;
        uint totalTicketSold;
    }

    Artist[] public artists;
    
    
    function createArtist(bytes32 _name, uint _artistCategory) public{
        artists.push(Artist(msg.sender,_name,_artistCategory,0));
        isAnArtist[msg.sender]=true;
        emit NewArtist(artists.length,_name,_artistCategory) ;
    }

    function artistsRegister(uint _id) public view returns(Artist memory ) {
        return artists[_id-1] ;
    }

    function modifyArtist(uint _artistId, bytes32 _name, uint _artistCategory, address payable _newOwner) public {
        require(msg.sender==artists[_artistId-1].owner,"You're not allowed to call this function.");
        artists[_artistId-1].name=_name;
        artists[_artistId-1].artistCategory=_artistCategory;
        artists[_artistId-1].owner=_newOwner;
        isAnArtist[_newOwner]=true;
        emit ModifiedArtist(_artistId,_name,_artistCategory) ;

    }





    event NewVenue(uint venueId,bytes32 name,uint capacity,uint standardComission);
    event ModifiedVenue(uint venueId,bytes32 name,uint capacity,uint standardComission);

    mapping (address=>bool) public isAnVenue;
        
    struct Venue{
        address payable owner;
        bytes32 name;
        uint capacity;
        uint standardComission;
    }

    Venue[] public venues;
    
    function createVenue(bytes32 _name, uint _capacity, uint _standardComission) public{
        venues.push(Venue(msg.sender,_name,_capacity,_standardComission));
        isAnVenue[msg.sender]=true;
        emit NewVenue(venues.length,_name,_capacity,_standardComission);
    }

   function  venuesRegister(uint _id) public view returns(Venue memory){
       return venues[_id-1]; 
   }

   function modifyVenue(uint _venueId, bytes32 _name, uint _capacity, uint _standardComission, address payable _newOwner) public {
        require(msg.sender==venues[_venueId-1].owner,"You're not allowed to call this function.");
        venues[_venueId-1].name=_name;
        venues[_venueId-1].capacity=_capacity;
        venues[_venueId-1].standardComission=_standardComission;
        venues[_venueId-1].owner=_newOwner;
        isAnVenue[_newOwner]=true;
        emit ModifiedVenue(_venueId,_name,_capacity,_standardComission) ;
   }

    

    event NewConcert(uint artistId,uint venueId,uint concertDate,uint ticketPrice);
    event NewTicket(uint concertId);

    struct Concert{
        address owner;
        uint artistId;
        uint venueId;
        uint concertDate;
        uint ticketPrice;
        bool validatedByArtist;
        bool validatedByVenue;
        uint totalSoldTicket;
        uint totalMoneyCollected;
        

    }

    struct Ticket{
        address owner;
        uint concertId;
        bool isAvailable;
        bool isAvailableForSale;
        uint amountPaid;
    }

    Concert[] public concerts;
    Ticket[] public tickets;


    function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice) public {
        if(isAnArtist[msg.sender]==true){
            concerts.push(Concert(msg.sender,_artistId,_venueId,_concertDate,_ticketPrice,true,false,0,0));
        } else if(isAnVenue[msg.sender]==true) {
            concerts.push(Concert(msg.sender,_artistId,_venueId,_concertDate,_ticketPrice,false,true,0,0));
        } else{
            concerts.push(Concert(msg.sender,_artistId,_venueId,_concertDate,_ticketPrice,false,false,0,0));
        }

        emit NewConcert(_artistId,_venueId,_concertDate,_ticketPrice);
    }

    function concertsRegister(uint _id) public view returns(Concert memory){
        return concerts[_id-1];
    }

    function validateConcert(uint _concertId) public{
        require(isAnArtist[msg.sender]==true || isAnVenue[msg.sender]==true,"Only artists and venues can call this funtion."); 
        if(isAnArtist[msg.sender]==true){
            concerts[_concertId-1].validatedByArtist=true;
        }else {
            concerts[_concertId-1].validatedByVenue=true;
        }

    }


    function createTicket(address _owner,uint _concertId, bool _isAvaible,uint _amount) public{
        tickets.push(Ticket(_owner,_concertId,_isAvaible,false,_amount));
        concerts[_concertId-1].totalSoldTicket+=1;
        concerts[_concertId-1].totalMoneyCollected+=_amount;
        emit NewTicket(_concertId);        
    }
    
    function emitTicket(uint _concertId, address payable _ticketOwner) public {
        require(isAnArtist[msg.sender]==true);
        createTicket(_ticketOwner,_concertId,true,0);
    }

    function ticketsRegister(uint _id )public view returns(Ticket memory){
        return tickets[_id-1];
    }

    

    function useTicket(uint _ticketId) public{
        require(msg.sender==tickets[_ticketId-1].owner,"It's not your ticket.");
        require(concerts[(tickets[_ticketId-1].concertId)-1].concertDate<=now+ 1 days,"Concert not start...");
        require(concerts[(tickets[_ticketId-1].concertId)-1].validatedByVenue==true,"No validation from venue.");
        tickets[_ticketId-1].isAvailable=false;
        tickets[_ticketId-1].owner=address(0);
        
    }



    function buyTicket(uint _concertId) public payable{
        createTicket(msg.sender,_concertId,true,msg.value);
    }

    function transferTicket(uint _ticketId, address payable _newOwner) public{
        require(msg.sender==tickets[_ticketId-1].owner);
        tickets[_ticketId-1].owner=_newOwner;
    }


    function cashOutConcert(uint _concertId, address payable _cashOutAddress) public {
        require(concerts[_concertId-1].concertDate<=now,"Concert not start.");
        require(concerts[_concertId-1].owner==msg.sender,"You are not allowed to cash out.");
        uint totalAmountSale=concerts[_concertId-1].totalMoneyCollected;
        uint venuecash=totalAmountSale* venues[concerts[_concertId-1].venueId-1].standardComission/10000;
        uint artistcash=totalAmountSale- venuecash;
        venues[concerts[_concertId-1].venueId-1].owner.transfer(venuecash);
        _cashOutAddress.transfer(artistcash);
        artists[concerts[_concertId-1].artistId-1].totalTicketSold+=concerts[_concertId-1].totalSoldTicket;
    }

    
    

    function offerTicketForSale(uint _ticketId, uint _salePrice) public {
        require(tickets[_ticketId-1].owner==msg.sender,"It's not your ticket.");
        require(_salePrice<=tickets[_ticketId-1].amountPaid,"You can't sell a ticket for more than you paid for it.");
        tickets[_ticketId-1].isAvailableForSale=true;
        tickets[_ticketId-1].amountPaid=_salePrice;
    } 

    function buySecondHandTicket(uint _ticketId) public payable {
        require(tickets[_ticketId-1].isAvailableForSale==true,"Ticket is not avaible to buy.");
        require(msg.value==tickets[_ticketId-1].amountPaid,"It's not the good price of the ticket.");
        require(tickets[_ticketId-1].isAvailable==true,"Ticket is not avaible.");
        //tickets[_ticketId-1].owner.send(msg.value);
        tickets[_ticketId-1].owner=msg.sender;
    }


}