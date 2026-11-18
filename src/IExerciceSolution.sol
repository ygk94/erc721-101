// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IExerciceSolution is IERC721 {
    // Breeding function
    function isBreeder(address account) external returns (bool);

    function registrationPrice() external returns (uint256);

    function registerMeAsBreeder() external payable;

    function declareAnimal(uint256 sex, uint256 legs, bool wings, string calldata name) external returns (uint256);

    function getAnimalCharacteristics(uint256 animalNumber)
        external
        returns (string memory _name, bool _wings, uint256 _legs, uint256 _sex);

    function declareDeadAnimal(uint256 animalNumber) external;

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    // Selling functions
    function isAnimalForSale(uint256 animalNumber) external view returns (bool);

    function animalPrice(uint256 animalNumber) external view returns (uint256);

    function buyAnimal(uint256 animalNumber) external payable;

    function offerForSale(uint256 animalNumber, uint256 price) external;

    // Reproduction functions

    function declareAnimalWithParents(
        uint256 sex,
        uint256 legs,
        bool wings,
        string calldata name,
        uint256 parent1,
        uint256 parent2
    ) external returns (uint256);

    function getParents(uint256 animalNumber) external returns (uint256, uint256);

    function canReproduce(uint256 animalNumber) external returns (bool);

    function reproductionPrice(uint256 animalNumber) external view returns (uint256);

    function offerForReproduction(uint256 animalNumber, uint256 priceOfReproduction) external returns (uint256);

    function authorizedBreederToReproduce(uint256 animalNumber) external returns (address);

    function payForReproduction(uint256 animalNumber) external payable;
}
