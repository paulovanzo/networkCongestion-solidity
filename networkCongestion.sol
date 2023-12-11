// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract networkCongestionContract {

    // Estrutura para armazenar título, pergunta, quantidade de tokens e status
    struct Question {
        string title;
        string text;
        string[] answers;
        uint256 qtTokens;
        bool done;
        address addrsAnswer;
    }

    // Mapeamento para armazenar as estruturas por índice
    mapping(uint256 => Question) public questions;

    // Evento para notificar a marcação da estrutura
    event QuestionSatified(address indexed marcador, uint256 indice, uint256 tokensRecebidos);

    // Função para adicionar uma nova estrutura
    function addQuestion(uint256 _indice, string memory _title, string memory _text, uint256 _qtTokens) external {
        questions[_indice] = Question(_title, _text, new string[](0), _qtTokens, false, address(0));
    }

    // Função para marcar uma estrutura por um endereço específico
    function markQuestion(uint256 _indice) external {
        Question storage question = questions[_indice];
        require(!question.done, "Answer already satisfied");

        question.done = true;
        question.addrsAnswer = msg.sender;

        uint256 tokensToAnswer = (question.qtTokens * 80) / 100;
        // Envia 80% dos tokens armazenados na estrutura para o endereço que respondeu "corretamente" e fez o dono da pergunta a marcar 
        // (Lembrando que seria necessário ter implementado um mecanismo para controlar os tokens, como um ERC-20)
        emit QuestionSatified(msg.sender, _indice, tokensToAnswer);
    }

}

contract NetworkCongestionToken is IERC20 {
    string public name = "ChannelLoad";
    string public symbol = "CHNL";
    uint8 public decimals = 18; // Decimais do token
    uint256 public override totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowed[sender][msg.sender], "Insufficient allowance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowed[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}
