// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Exam {
    address  _addr;
    mapping(address => uint256) balance;
    struct Student {
        address  addr;
        string name;
        string school;
        int age;
    }
    uint256 listprice = 0.0025 ether;
    Student student;
    mapping(address => Student) Person;

    function getPrice()
    public view returns(uint256){
        return listprice;
    }

    function createStudent(
        address addr,
        string name,
        string school,
        int age) public {
        student = Student(
            addr,
            name,
            school,
            age
        );
        _addr = addr;
        Person[addr] = student;
    }


    function getStudent(address addr) public view returns(Student){
        return (Person[addr]);
    }

    function getAddr() public view returns(address){
        return _addr;
    }
}
