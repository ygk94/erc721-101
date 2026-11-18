# ERC721-101 — Animal NFT

Solution du TD [ERC721-101](https://github.com/Elli610/Blockchain-101/tree/main/workshops/solidity/erc721-101) (Sepolia).

- `src/AnimalNFT.sol` : contrat ERC721 (breeders, mint/burn, vente, reproduction)
- `test/AnimalNFT.t.sol` : rejoue les Evaluators sur un fork de Sepolia
- `script/Deploy.s.sol` : déploiement

```shell
cp .env.example .env     # remplir SEPOLIA_RPC_URL et PRIVATE_KEY
source .env
forge test -vv
forge create src/AnimalNFT.sol:AnimalNFT --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

> `forge script` estime le gas sur une simulation locale (~5,3 M) alors que Sepolia en demande beaucoup plus : la transaction échoue faute de gas. `forge create` estime directement sur Sepolia. L'optimiseur (`foundry.toml`) ramène le déploiement sous la limite de ~16,7 M de gas par transaction.

## Résultat

Contrat déployé : [`0xEb60aC49ae7c9Aa2c87900AcC58B0335545E8965`](https://sepolia.etherscan.io/address/0xEb60aC49ae7c9Aa2c87900AcC58B0335545E8965) — **20 / 20 points**, tous les exercices validés (ex1 → ex7c).

| Contrat | Adresse (Sepolia) |
|---|---|
| TDToken (points) | `0x36f7439dB3b9E408B095A9895456A95BA5450D24` |
| Evaluator | `0xa39ac9c5eF0582f5D0b21770e34c4c54d6e46Fa6` |
| Evaluator2 | `0xB6C6cf310456Bd0dEE01162A9150EC7ccA146936` |
| **AnimalNFT (ma solution)** | `0xEb60aC49ae7c9Aa2c87900AcC58B0335545E8965` |
