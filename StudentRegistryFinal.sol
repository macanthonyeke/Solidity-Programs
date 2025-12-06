// SPDX-License-Identifier: MIT
pragma solidity 0.8.18; // solidity versions

contract StudentRegistry {

    string public schoolName;

    address public teacher;

    address[] public studentAddresses;

    enum Grade {None, Fail, Pass, Excellent}

    struct Student {
        string name;
        uint[] marks;
        uint total;
        Grade grade;
        bool registered;
    }

    mapping (address => Student) public students;
    mapping (address => uint) public studentIndex;

    constructor (string memory _schoolName) {
        schoolName = _schoolName;
        teacher = msg.sender;
    }

    modifier onlyTeacher() {
        require(msg.sender == teacher, "only teacher can perform action");
        _;
    }

    event StudentRegistered(address indexed student, string name);
    event MarkAdded(address indexed student, uint mark);
    event GradeUpdated(address indexed student, Grade newGrade);
    event StudentRemoved(address indexed student);
    
    function registerStudent(address _addr, string memory _name) public onlyTeacher {
        require(!students[_addr].registered, "already registered");
        require(_addr != address(0), "invalid address");

        students[_addr].name = _name;
        students[_addr].total = 0;
        students[_addr].grade = Grade.None;
        students[_addr].registered = true;

        studentAddresses.push(_addr);
        studentIndex[_addr] = studentAddresses.length;

        emit StudentRegistered(_addr, _name);
    }

    function addMark (address _addr, uint _mark) public onlyTeacher {
        require(students[_addr].registered, "student not registered");
        require(_mark <= 100, "invalid score");

        students[_addr].marks.push(_mark);
        students[_addr].total += _mark;

        emit MarkAdded(_addr, _mark);
    }

    function getMark (address _addr) public view returns(uint[] memory marks) {
        require(students[_addr].registered, "not registered");

        return students[_addr].marks;
    }

    function getAverage (address _addr) public view returns(uint) {
        require(students[_addr].registered, "not registered");

        if(students[_addr].marks.length == 0) {
            return 0;
        }
        else {
            return students[_addr].total / students[_addr].marks.length;
        }
    }

    function setGrade (address _addr) public onlyTeacher {
        require(students[_addr].registered, "not registered");

        uint avg = getAverage(_addr);

        Grade newGrade;

        if (avg < 40) {
            newGrade = Grade.Fail;
        }
        else if (avg < 70) {
            newGrade = Grade.Pass;
        }
        else {
            newGrade = Grade.Excellent;
        }

        students[_addr].grade = newGrade;

        emit GradeUpdated(_addr, newGrade);
    }

    function setGradeName (address _addr) public view returns(string memory) {
        require(students[_addr].registered, "not registered");

        Grade g = students[_addr].grade;

        if (g == Grade.None) {
            return "None";
        }
        else if (g == Grade.Fail) {
            return "Fail";
        }
        else if (g == Grade.Pass) {
            return "Pass";
        }
        else {
            return "Excellent";
        }
    }

    function getStudent (address _addr) public view returns(string memory name, uint[] memory marks, string memory stringName, bool registered) {
        require(students[_addr].registered, "not registered");

        Student storage s = students[_addr];

        return (s.name, s.marks, setGradeName(_addr), s.registered);
    }

    function removeStudent (address _addr) external onlyTeacher {

        uint idxPlusOne = studentIndex[_addr];
        require(idxPlusOne != 0, "not registered");

        uint idx = idxPlusOne - 1;
        uint lastIndex = studentAddresses.length - 1;

        if (idx != lastIndex) {
            // swap last address into position idx
            address lastAddr = studentAddresses[lastIndex];
            studentAddresses[idx] = lastAddr;
            // update moved student's index mapping to new idx+1
            studentIndex[lastAddr] = idx + 1;
        }
        
        // remove last element
        studentAddresses.pop();

        // clear mappings & storage for removed student
        studentIndex[_addr] = 0;
        delete students[_addr];

        emit StudentRemoved(_addr);
    }
}