// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "../src/AnimalNFT.sol";
import "../src/IExerciceSolution.sol";

interface IEvaluator {
    function submitExercice(address studentExercice) external;
    function ex1_testERC721() external;
    function ex2a_getAnimalToCreateAttributes() external;
    function ex2b_testDeclaredAnimal(uint256 animalNumber) external;
    function ex3_testRegisterBreeder() external;
    function ex4_testDeclareAnimal() external;
    function ex5_declareDeadAnimal() external;
    function ex6a_auctionAnimal_offer() external;
    function ex6b_auctionAnimal_buy(uint256 animalForSale) external;
    function exerciceProgression(address, uint256) external view returns (bool);
    function readName(address) external view returns (string memory);
    function readLegs(address) external view returns (uint256);
    function readSex(address) external view returns (uint256);
    function readWings(address) external view returns (bool);
}

interface IEvaluator2 {
    function submitExercice(address studentExercice) external;
    function ex2a_getAnimalToCreateAttributes() external;
    function ex7a_breedAnimalWithParents(uint256 parent1, uint256 parent2) external;
    function ex7b_offerAnimalForReproduction() external;
    function ex7c_payForReproduction(uint256 animalAvailableForReproduction) external;
    function exerciceProgression(address, uint256) external view returns (bool);
}

/// Rejoue les vérifications de l'Evaluator sur un fork de Sepolia.
/// Lancer : forge test -vv            (tous)
///          forge test --mt ex3 -vv   (un seul exo)
contract AnimalNFTTest is Test {
    IEvaluator constant EVALUATOR = IEvaluator(0xa39ac9c5eF0582f5D0b21770e34c4c54d6e46Fa6);
    IEvaluator2 constant EVALUATOR2 = IEvaluator2(0xB6C6cf310456Bd0dEE01162A9150EC7ccA146936);
    address constant ME = 0xD6FabC0A420127F493DeECdb461EaD4DAD644071;

    IExerciceSolution nft;

    function setUp() public {
        string memory rpc = vm.envOr("SEPOLIA_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            vm.skip(true); // pas de RPC (ex : CI GitHub) -> tests ignorés
            return;
        }
        vm.createSelectFork(rpc);
        vm.deal(ME, 1 ether);
        vm.startPrank(ME);
        AnimalNFT deployed = new AnimalNFT();
        nft = IExerciceSolution(address(deployed));
        EVALUATOR.submitExercice(address(nft));
        _done(0);
    }

    // ---------- helpers ----------

    function _becomeBreeder() internal {
        if (!nft.isBreeder(ME)) {
            nft.registerMeAsBreeder{value: nft.registrationPrice()}();
        }
    }

    /// Crée (en tant que ME) l'animal attribué par ex2a et renvoie son numéro
    function _declareAssignedAnimal() internal returns (uint256) {
        return nft.declareAnimal(
            EVALUATOR.readSex(ME), EVALUATOR.readLegs(ME), EVALUATOR.readWings(ME), EVALUATOR.readName(ME)
        );
    }

    function _done(uint256 ex) internal view {
        assertTrue(EVALUATOR.exerciceProgression(ME, ex), "exo non valide");
    }

    // ---------- exos ----------

    function test_ex1() public {
        EVALUATOR.ex1_testERC721();
        _done(1);
    }

    function test_ex2() public {
        EVALUATOR.ex2a_getAnimalToCreateAttributes();
        _becomeBreeder();
        uint256 id = _declareAssignedAnimal();
        nft.transferFrom(ME, address(EVALUATOR), id);
        EVALUATOR.ex2b_testDeclaredAnimal(id);
        _done(2);
    }

    function test_ex3() public {
        EVALUATOR.ex3_testRegisterBreeder();
        _done(3);
    }

    function test_ex4() public {
        EVALUATOR.ex2a_getAnimalToCreateAttributes();
        EVALUATOR.ex3_testRegisterBreeder();
        EVALUATOR.ex4_testDeclareAnimal();
        _done(4);
    }

    function test_ex5() public {
        EVALUATOR.ex1_testERC721(); // ME récupère l'animal n°1
        EVALUATOR.ex2a_getAnimalToCreateAttributes();
        EVALUATOR.ex3_testRegisterBreeder();
        EVALUATOR.ex4_testDeclareAnimal(); // l'Evaluator a un animal
        EVALUATOR.ex5_declareDeadAnimal();
        _done(5);
    }

    function test_ex6() public {
        EVALUATOR.ex2a_getAnimalToCreateAttributes();
        EVALUATOR.ex3_testRegisterBreeder();
        EVALUATOR.ex4_testDeclareAnimal(); // l'Evaluator a un animal
        EVALUATOR.ex6a_auctionAnimal_offer();
        _done(61);

        _becomeBreeder();
        uint256 id = _declareAssignedAnimal();
        nft.offerForSale(id, 0.0001 ether);
        EVALUATOR.ex6b_auctionAnimal_buy(id);
        _done(62);
    }

    // ---------- Evaluator2 (exo 7) ----------

    function _setupEvaluator2() internal returns (uint256 p1, uint256 p2) {
        EVALUATOR2.submitExercice(address(nft));
        AnimalNFT(address(nft)).addBreeder(address(EVALUATOR2));
        _becomeBreeder();
        // l'Evaluator2 doit posséder 2 animaux pour servir de parents
        p1 = nft.declareAnimal(0, 4, false, "papa");
        p2 = nft.declareAnimal(1, 4, false, "maman");
        nft.transferFrom(ME, address(EVALUATOR2), p1);
        nft.transferFrom(ME, address(EVALUATOR2), p2);
    }

    function test_ex7() public {
        EVALUATOR.ex1_testERC721(); // ME possède un animal (le n°1)
        (uint256 p1, uint256 p2) = _setupEvaluator2();

        EVALUATOR2.ex7a_breedAnimalWithParents(p1, p2);
        assertTrue(EVALUATOR2.exerciceProgression(ME, 71), "7a");

        EVALUATOR2.ex7b_offerAnimalForReproduction();
        assertTrue(EVALUATOR2.exerciceProgression(ME, 72), "7b");

        uint256 mine = nft.declareAnimal(1, 2, true, "etalon");
        nft.offerForReproduction(mine, 0.0001 ether);
        uint256 before = ME.balance;
        EVALUATOR2.ex7c_payForReproduction(mine);
        assertTrue(EVALUATOR2.exerciceProgression(ME, 73), "7c");
        assertEq(ME.balance, before + 0.0001 ether, "ME a ete paye");
    }

    /// Parcours complet, dans l'ordre exact du guide (une seule instance du contrat)
    function test_fullRun() public {
        EVALUATOR.ex1_testERC721();
        _done(1);

        EVALUATOR.ex2a_getAnimalToCreateAttributes();
        _becomeBreeder();
        uint256 id = _declareAssignedAnimal();
        nft.transferFrom(ME, address(EVALUATOR), id);
        EVALUATOR.ex2b_testDeclaredAnimal(id);
        _done(2);

        EVALUATOR.ex3_testRegisterBreeder();
        _done(3);
        EVALUATOR.ex4_testDeclareAnimal();
        _done(4);
        EVALUATOR.ex5_declareDeadAnimal();
        _done(5);
        EVALUATOR.ex6a_auctionAnimal_offer();
        _done(61);

        uint256 sale = nft.declareAnimal(0, 4, false, "a vendre");
        nft.offerForSale(sale, 0.0001 ether);
        EVALUATOR.ex6b_auctionAnimal_buy(sale);
        _done(62);

        (uint256 p1, uint256 p2) = _setupEvaluator2();
        EVALUATOR2.ex7a_breedAnimalWithParents(p1, p2);
        EVALUATOR2.ex7b_offerAnimalForReproduction();
        uint256 mine = nft.declareAnimal(1, 2, true, "etalon");
        nft.offerForReproduction(mine, 0.0001 ether);
        EVALUATOR2.ex7c_payForReproduction(mine);
        assertTrue(EVALUATOR2.exerciceProgression(ME, 73), "7c");
    }
}
