// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract red_envelope {

    struct redbag {
        
        uint256 amount;
        uint256 leixing;
        uint256 maxnum;
        uint256 time;
        uint256 left_money;
        bytes32 kouling;
        address sender;
        address[] qiang;
    }
    
    mapping (address => uint256) countNum;
    mapping (address => mapping(uint256 => redbag)) public whosredbag;
    
    event Fahongbao(address indexed _sender,uint256 _amount,uint256 _maxnum);
    event BeFriend(address _mine,address _friend);
    event GetRed(address indexed _mine,address _sender,uint256 _whichRB,uint256 _amount);
    event GetRealse(address _sender,uint256 _leftRed,uint256 _nowTime);
    
    
    mapping (address => address[]) friend;

    function beFriend(address _friend) public{
        require(!isFriend(_friend,msg.sender),"already friend");
        friend[msg.sender].push(_friend);
        emit BeFriend(msg.sender,_friend);
    }
    
    function  _countNum(address _Addr) internal returns(uint256 _whichRB){
        countNum[_Addr] += 1;
        _whichRB = countNum[_Addr];
        return _whichRB;
    }

    function getRealse(address _leftRed,uint256 _whichRB) public returns(bool) {
        redbag storage _newSender = whosredbag[_leftRed][_whichRB];
        require(msg.sender == _newSender.sender,"you are not the owner");
        require(_newSender.time < block.timestamp,"time isn't out");
        uint256 _amount = _newSender.left_money;
        _newSender.left_money -= _amount;
        (bool success,) = payable(msg.sender).call{value:_amount}("");
        emit GetRealse(_newSender.sender,_amount,block.timestamp);
        return success;
    }

    function fahongbao(
        uint256 _maxnum,
        uint256 _time,
        bytes32 _kouling,
        uint256 _leixing

    ) public payable
    {
        redbag storage _newSender = whosredbag[msg.sender][_countNum(msg.sender)];
        uint256 _nowTime = block.timestamp;
        _newSender.time = _time + _nowTime;
        _newSender.kouling = _kouling;
        _newSender.amount = msg.value;
        _newSender.sender = msg.sender;
        _newSender.maxnum = _maxnum;
        _newSender.leixing = _leixing;
        _newSender.left_money = msg.value;
        emit Fahongbao(_newSender.sender,_newSender.amount,_newSender.maxnum);
    }

    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    // 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    function kouling(string memory _kouling) public pure returns(bytes32 result){
        assembly{
            result := mload(add(_kouling,32))
         }
    }

    function getRed(address _who,bytes32 _kouling,uint256 _whichRB) public returns(bool)  {
        require(isFriend(msg.sender,_who),"not friend");
        redbag storage _newSender = whosredbag[_who][_whichRB];
        require(_kouling == _newSender.kouling);
        require(_newSender.time > block.timestamp,"time is out");
        require(_isqiang(_who,_whichRB));
        if(_newSender.qiang.length == _newSender.maxnum - 1){
            uint256 _amount = _newSender.left_money;
            _newSender.qiang.push(msg.sender);
            _newSender.left_money -= _amount;
            (bool success,) = payable(msg.sender).call{value:_amount}("");
            emit GetRed(msg.sender,_newSender.sender,_whichRB,_amount);
            return success;
        }
        else{uint256 _amount = _perValue(_who,_newSender.leixing,_whichRB);
            _newSender.qiang.push(msg.sender);
            _newSender.left_money -= _amount;
            (bool success,) = payable(msg.sender).call{value:_amount}("");
            emit GetRed(msg.sender,_newSender.sender,_whichRB,_amount);
            return success;
        }


    }

    function _isqiang(address _who,uint256 _whichRB) internal view returns(bool restult) {
        redbag memory _newSender = whosredbag[_who][_whichRB];
        for(uint256 i = 0; i < _newSender.qiang.length;i ++){
            require(msg.sender != _newSender.qiang[i],"you have already done this");
            }
        return true;
    }

    function isFriend(address _mine,address _owner) internal view returns(bool result) {
        for(uint256 i = 0; i < friend[_owner].length;i ++){
            if(_mine == friend[_owner][i]){
                result = true;
            }
        }
        return result;
           
    }

    function _perValue(address _owner,uint256 _type,uint256 _whichRB) internal view returns(uint256 restult) {
        require(_type < 2,"_type should be 1 or 0");
        redbag memory _newSender = whosredbag[_owner][_whichRB];
        uint256 _amount = _newSender.amount / _newSender.maxnum;
        if(_type == 1){
            return restult = _amount;
        }
        else if(_type == 0){
            return restult = (_random() * _amount) / 50 ;
        }
    }

    function _random() internal view returns(uint256 restult){
        bytes32 randomBytes = keccak256(abi.encodePacked(block.number, msg.sender, blockhash(block.timestamp-1)));
        return restult = (uint(randomBytes) % 100);
    }
}