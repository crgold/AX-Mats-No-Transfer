// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC1155Base.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";


contract Mats is PermissionsEnumerable, ERC1155Base {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

      constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    )
        ERC1155Base(
            _defaultAdmin,
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    *  @notice          Lets MINTER_ROLE mint NFTs to a recipient.
    *  @dev             - If `_tokenId == type(uint256).max` a new NFT at tokenId `nextTokenIdToMint` is minted. If the given
    *                     `tokenId < nextTokenIdToMint`, then additional supply of an existing NFT is being minted.
    *
    *  @param _to       The recipient of the NFTs to mint.
    *  @param _tokenId  The tokenId of the NFT to mint.
    *  @param _tokenURI The full metadata URI for the NFTs minted (if a new NFT is being minted).
    *  @param _amount   The amount of the same NFT to mint.
    */
    function mintTo(
        address _to,
        uint256 _tokenId,
        string memory _tokenURI,
        uint256 _amount
    ) public override onlyRole(MINTER_ROLE){
        require(_amount > 0, "Amount must be greater than zero");

        uint256 tokenIdToMint;
        uint256 nextIdToMint = nextTokenIdToMint();
    
        if (_tokenId == type(uint256).max) {
            tokenIdToMint = nextIdToMint;
            nextTokenIdToMint_ += 1;
            _setTokenURI(nextIdToMint, _tokenURI);
        } else {
            require(_tokenId < nextIdToMint, "invalid id");
            tokenIdToMint = _tokenId;
        }
    
        _mint(_to, tokenIdToMint, _amount, "");
    }

    /**
    *  @notice          Lets MINTER_ROLE mint multiple NEW NFTs at once to a recipient.
    *  @dev             If `_tokenIds[i] == type(uint256).max` a new NFT at tokenId `nextTokenIdToMint` is minted. If the given
    *                   `tokenIds[i] < nextTokenIdToMint`, then additional supply of an existing NFT is minted.
    *                   The metadata for each new NFT is stored at `baseURI/{tokenID of NFT}`
    *
    *  @param _to       The recipient of the NFT to mint.
    *  @param _tokenIds The tokenIds of the NFTs to mint.
    *  @param _amounts  The amounts of each NFT to mint.
    *  @param _baseURI  The baseURI for the `n` number of NFTs minted. The metadata for each NFT is `baseURI/tokenId`
    */
    function batchMintTo(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        string memory _baseURI
    ) public override onlyRole(MINTER_ROLE){
        require(_amounts.length > 0, "Minting zero tokens.");
        require(_tokenIds.length == _amounts.length, "Length mismatch.");

        uint256 nextIdToMint = nextTokenIdToMint();
        uint256 startNextIdToMint = nextIdToMint;

        uint256 numOfNewNFTs;

        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            if (_tokenIds[i] == type(uint256).max) {
                _tokenIds[i] = nextIdToMint;

                nextIdToMint += 1;
                numOfNewNFTs += 1;
            } else {
                require(_tokenIds[i] < nextIdToMint, "invalid id");
            }
        }

        if (numOfNewNFTs > 0) {
            _batchMintMetadata(startNextIdToMint, numOfNewNFTs, _baseURI);
        }

        nextTokenIdToMint_ = nextIdToMint;
        _mintBatch(_to, _tokenIds, _amounts, "");

    }

    /**
    *  @notice         Lets MINTER_ROLE burn a users NFTs.
    *
    *  @param _owner   The owner of the NFT to burn.
    *  @param _tokenId The tokenId of the NFT to burn.
    *  @param _amount  The amount of the NFT to burn.
    */
    function burn(
        address  _owner,
        uint256 _tokenId,
        uint256 _amount
    ) external override onlyRole(MINTER_ROLE){
        require(balanceOf[_owner][_tokenId] >= _amount, "Not enough materials owned");
        _burn(_owner, _tokenId, _amount);
    }

    /**
    *  @notice          Lets MINTER_ROLE burn NFTs of the given tokenIds from a users wallet.
    *
    *  @param _owner    The owner of the NFTs to burn.
    *  @param _tokenIds The tokenIds of the NFTs to burn.
    *  @param _amounts  The amounts of the NFTs to burn.
    */
    function burnBatch(
        address _owner,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external override onlyRole(MINTER_ROLE){
        require(_tokenIds.length == _amounts.length, "Length mismatch");
    
        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            require(balanceOf[_owner][_tokenIds[i]] >= _amounts[i], "Not enough materials owned");
        }
    
        _burnBatch(_owner, _tokenIds, _amounts);
    }

    /**
    *  @notice          Add switch for checking if a mat id is transfer enabled
    *
    *  @param operator  The function caller
    *  @param from      Where the NFT's originate
    *  @param to        Where they will be sent
    *  @param ids       The tokenIds of the NFTs.
    *  @param amounts   The amounts to be transferred.
    *  @param data      Any additional data that is required (unused)
    */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Restrict transfers by ensuring 'from' and 'to' are not zero address
        if (from != address(0) && to != address(0) && !hasRole(DEFAULT_ADMIN_ROLE, operator)) {
            revert("Transfers are disabled");
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length;) {
                totalSupply[ids[i]] += amounts[i];
                unchecked {
                    ++i;
                }
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length;) {
                totalSupply[ids[i]] -= amounts[i];
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
    *  @notice                  This function returns who is authorized to set the metadata for the contract.
    *
    *  @return success A boolean that determined whether msg.sender is authorized to set the contract uri
    */
    function _canSetContractURI() internal view virtual override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized to set contract URI");
        return true;
    }
}