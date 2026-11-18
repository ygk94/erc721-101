// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract AnimalNFT is ERC721Enumerable {
    // Exo 1 : le token 1 est donné à l'Evaluator dès le déploiement
    address constant EVALUATOR = 0xa39ac9c5eF0582f5D0b21770e34c4c54d6e46Fa6;

    address public owner;

    constructor() ERC721("Animal NFT", "ANML") {
        owner = msg.sender;
        _mint(EVALUATOR, 1);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner of the contract");
        _;
    }

    modifier onlyBreeder() {
        require(allowbreeder[msg.sender], "Not allow breeder");
        _;
    }

    modifier onlyAnimalOwner(uint256 animalNumber) {
        require(msg.sender == ownerOf(animalNumber), "Not owner");
        _;
    }

    struct Animal {
        string name;
        bool wings;
        uint256 legs;
        uint256 sex;
    }

    mapping(uint256 => Animal) private animallist;

    mapping(address => bool) private allowbreeder;

    uint256 compteur = 1;

    // ---------------------------------------------------------------
    // Exo 2 / 4 : déclarer un animal (mint)
    // ---------------------------------------------------------------
    function declareAnimal(uint256 sex, uint256 legs, bool wings, string calldata name)
        external
        onlyBreeder
        returns (uint256)
    {
        return _createAnimal(sex, legs, wings, name);
    }

    function _createAnimal(uint256 sex, uint256 legs, bool wings, string calldata name) internal returns (uint256) {
        compteur += 1;
        _mint(msg.sender, compteur);
        animallist[compteur] = Animal(name, wings, legs, sex);
        return compteur;
    }

    function getAnimalCharacteristics(uint256 animalNumber)
        external
        view
        returns (string memory _name, bool _wings, uint256 _legs, uint256 _sex)
    {
        Animal storage a = animallist[animalNumber];
        return (a.name, a.wings, a.legs, a.sex);
    }

    // ---------------------------------------------------------------
    // Exo 3 : enregistrement des breeders
    // ---------------------------------------------------------------
    uint256 public registrationPrice = 0.0001 ether;

    function registerMeAsBreeder() external payable {
        require(msg.value == registrationPrice, "Wrong price");
        allowbreeder[msg.sender] = true;
    }

    function isBreeder(address customeraddress) external view returns (bool) {
        return allowbreeder[customeraddress];
    }

    /// L'Evaluator2 ne s'enregistre pas tout seul : le propriétaire du contrat l'ajoute.
    function addBreeder(address breeder) external onlyOwner {
        allowbreeder[breeder] = true;
    }

    // ---------------------------------------------------------------
    // Exo 5 : déclarer un animal mort (burn)
    // ---------------------------------------------------------------
    function declareDeadAnimal(uint256 animalNumber) external onlyAnimalOwner(animalNumber) {
        _burn(animalNumber);
        delete animallist[animalNumber];
        delete parents[animalNumber];
    }

    // ---------------------------------------------------------------
    // Exo 6 : vente
    // ---------------------------------------------------------------
    mapping(uint256 => bool) private forSale;
    mapping(uint256 => uint256) private salePrice;

    function isAnimalForSale(uint256 animalNumber) external view returns (bool) {
        return forSale[animalNumber];
    }

    function animalPrice(uint256 animalNumber) external view returns (uint256) {
        return salePrice[animalNumber];
    }

    function offerForSale(uint256 animalNumber, uint256 price) external onlyAnimalOwner(animalNumber) {
        forSale[animalNumber] = true;
        salePrice[animalNumber] = price;
    }

    function buyAnimal(uint256 animalNumber) external payable {
        require(forSale[animalNumber], "Animal not for sale");
        require(msg.value == salePrice[animalNumber], "Wrong price");
        address seller = ownerOf(animalNumber);
        require(seller != msg.sender, "Already yours");

        // _update (ci-dessous) remet la vente à zéro pendant le transfert
        _transfer(seller, msg.sender, animalNumber);

        (bool ok,) = payable(seller).call{value: msg.value}("");
        require(ok, "Payment failed");
    }

    // ---------------------------------------------------------------
    // Exo 7 : parents et reproduction (évalués par Evaluator2)
    // ---------------------------------------------------------------
    struct Parents {
        uint256 parent1;
        uint256 parent2;
    }

    mapping(uint256 => Parents) private parents;
    mapping(uint256 => bool) private reproductionOffered;
    mapping(uint256 => uint256) private reproPrice;
    mapping(uint256 => address) private authorizedBreeder;

    /// On peut utiliser un parent si on le possède, ou si on a payé pour le faire reproduire.
    /// Le droit payé ne sert qu'une seule fois.
    function _useParent(uint256 animalNumber) internal {
        address parentOwner = ownerOf(animalNumber); // revert si l'animal n'existe pas
        if (parentOwner == msg.sender) return;
        require(authorizedBreeder[animalNumber] == msg.sender, "Not allowed to reproduce this animal");
        authorizedBreeder[animalNumber] = address(0);
    }

    function declareAnimalWithParents(
        uint256 sex,
        uint256 legs,
        bool wings,
        string calldata name,
        uint256 parent1,
        uint256 parent2
    ) external onlyBreeder returns (uint256) {
        require(parent1 != parent2, "Same parents");
        _useParent(parent1);
        _useParent(parent2);

        uint256 id = _createAnimal(sex, legs, wings, name);
        parents[id] = Parents(parent1, parent2);
        return id;
    }

    function getParents(uint256 animalNumber) external view returns (uint256, uint256) {
        return (parents[animalNumber].parent1, parents[animalNumber].parent2);
    }

    function canReproduce(uint256 animalNumber) external view returns (bool) {
        return reproductionOffered[animalNumber];
    }

    function reproductionPrice(uint256 animalNumber) external view returns (uint256) {
        return reproPrice[animalNumber];
    }

    function offerForReproduction(uint256 animalNumber, uint256 priceOfReproduction)
        external
        onlyAnimalOwner(animalNumber)
        returns (uint256)
    {
        reproductionOffered[animalNumber] = true;
        reproPrice[animalNumber] = priceOfReproduction;
        return animalNumber;
    }

    function authorizedBreederToReproduce(uint256 animalNumber) external view returns (address) {
        return authorizedBreeder[animalNumber];
    }

    function payForReproduction(uint256 animalNumber) external payable {
        require(reproductionOffered[animalNumber], "Not available for reproduction");
        require(msg.value == reproPrice[animalNumber], "Wrong price");

        authorizedBreeder[animalNumber] = msg.sender;

        (bool ok,) = payable(ownerOf(animalNumber)).call{value: msg.value}("");
        require(ok, "Payment failed");
    }

    // ---------------------------------------------------------------
    // À chaque transfert / burn : on annule les offres en cours
    // ---------------------------------------------------------------
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = super._update(to, tokenId, auth);
        if (from != address(0)) {
            delete forSale[tokenId];
            delete salePrice[tokenId];
            delete reproductionOffered[tokenId];
            delete reproPrice[tokenId];
            delete authorizedBreeder[tokenId];
        }
        return from;
    }
}
