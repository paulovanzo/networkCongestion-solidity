// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    /* To do
    function name() public view returns (string)
    function symbol() public view returns (string)
    function decimals() public view returns (uint8)
    function totalSupply() public view returns (uint256)
    function balanceOf(address _owner) public view returns (uint256 balance)
    function transfer(address _to, uint256 _value) public returns (bool success)
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    function approve(address _spender, uint256 _value) public returns (bool success)
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)

    event Transfer(address indexed _from, address indexed _to, uint256 _value)
    event Approval(address indexed _owner, address indexed _spender, uint256 _value)
    */
}