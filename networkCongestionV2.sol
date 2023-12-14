// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PerguntasERespostas {
    using SafeMath for uint256;

    address public owner;
    uint256 public recompensaPadrao = 1000000000000000000; // 100 SEP
    uint256 public taxaDoDono = 15; // 15%
    uint256 public taxaDaComunidade = 5; // 5%
    uint256 public prazoUpvotes = 1 days; // 1 dia em segundos

    struct Pergunta {
        string titulo;
        string corpo;
        address payable autor;
        uint256 recompensa;
        uint256 melhorResposta;
        uint256 prazoUpvotes;
    }

    struct Resposta {
        address payable autor;
        string corpo;
        uint256 upvotes;
    }

    Pergunta[] public perguntas;
    mapping(address => Pergunta) public perguntasPorAutor;
    mapping(uint256 => Resposta[]) public respostas;
    mapping(uint256 => mapping(address => bool)) public upvotes;

    event PerguntaCriada(string titulo, string corpo, uint256 recompensa);
    event RespostaCriada(uint256 perguntaId, address autor, string corpo);
    event MelhorRespostaEscolhida(uint256 perguntaId, uint256 melhorRespostaId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Somente o dono pode chamar essa funcao");
        _;
    }

    modifier onlyQuestionAuthor(uint256 _perguntaId) {
        require(msg.sender == perguntas[_perguntaId].autor, "Somente o autor da pergunta pode chamar essa funcao");
        _;
    }

    // Função interna para expirar uma pergunta e distribuir automaticamente recompensa à comunidade
    function expirarPergunta(uint256 _perguntaId) internal {
        Pergunta storage pergunta = perguntas[_perguntaId];
        require(block.timestamp > pergunta.prazoUpvotes, "O prazo para upvotes ainda nao expirou");

        if (pergunta.melhorResposta == 0) {
            pergunta.melhorResposta = 1; // Escolhe automaticamente a primeira resposta como a melhor
        }

        uint256 recompensaComunidade = pergunta.recompensa * taxaDaComunidade / 100;
        respostas[_perguntaId][pergunta.melhorResposta - 1].autor.transfer(recompensaComunidade);
    }

    // Função para criar uma nova pergunta
    function criarPergunta(string memory _titulo, string memory _corpo, uint256 _recompensa) public {
        require(_recompensa >= recompensaPadrao, "A recompensa deve ser maior ou igual a 100 SEP");

        Pergunta memory pergunta = Pergunta(_titulo, _corpo, payable(msg.sender), _recompensa, 0, block.timestamp.add(prazoUpvotes));
        perguntas.push(pergunta);
        perguntasPorAutor[msg.sender] = pergunta;

        owner = msg.sender; // Define o dono do contrato

        emit PerguntaCriada(pergunta.titulo, pergunta.corpo, pergunta.recompensa);
    }

    // Função para responder a uma pergunta
    function responderPergunta(uint256 _perguntaId, string memory _corpo) public {
        Pergunta storage pergunta = perguntas[_perguntaId];
        require(pergunta.recompensa > 0, "A pergunta nao tem recompensa");

        Resposta memory resposta = Resposta(payable(msg.sender), _corpo, 0);
        respostas[_perguntaId].push(resposta);

        emit RespostaCriada(_perguntaId, resposta.autor, resposta.corpo);
    }

    // Função para escolher a melhor resposta e distribuir recompensas
    function escolherMelhorResposta(uint256 _perguntaId, uint256 _respostaId) public onlyQuestionAuthor(_perguntaId) {
        Pergunta storage pergunta = perguntas[_perguntaId];
        require(pergunta.recompensa > 0, "A pergunta nao tem recompensa");
        require(block.timestamp <= pergunta.prazoUpvotes, "O prazo para escolher a melhor resposta expirou");

        pergunta.melhorResposta = _respostaId;

        emit MelhorRespostaEscolhida(_perguntaId, _respostaId);

        uint256 recompensaAutor = pergunta.recompensa * taxaDoDono / 100;
        uint256 recompensaMelhorResposta = pergunta.recompensa * (100 - taxaDoDono) / 100;

        pergunta.autor.transfer(recompensaAutor);
        respostas[_perguntaId][_respostaId].autor.transfer(recompensaMelhorResposta);

        expirarPergunta(_perguntaId);
    }

    // Função para retornar todas as perguntas
    function retornarTodasPerguntas() public view returns(Pergunta[] memory){
        return perguntas;
    }

    // Função para votar em uma resposta
    function upvoteResposta(uint256 _perguntaId, uint256 _respostaId) public {
        require(_respostaId < respostas[_perguntaId].length, "Resposta nao encontrada");
        require(!upvotes[_perguntaId][msg.sender], "Voce ja votou nesta resposta");

        upvotes[_perguntaId][msg.sender] = true;
        respostas[_perguntaId][_respostaId].upvotes++;
    }

    // Função para distribuir recompensa à comunidade após o prazo de upvotes expirar
    function distribuirRecompensaComunidade(uint256 _perguntaId) public {
        Pergunta storage pergunta = perguntas[_perguntaId];
        require(block.timestamp > pergunta.prazoUpvotes, "O prazo para upvotes ainda nao expirou");

        uint256 melhorRespostaId = 0;
        uint256 melhorRespostaUpvotes = 0;
        for (uint256 i = 0; i < respostas[_perguntaId].length; i++) {
            if (respostas[_perguntaId][i].upvotes > melhorRespostaUpvotes) {
                melhorRespostaId = i;
                melhorRespostaUpvotes = respostas[_perguntaId][i].upvotes;
            }
        }

        uint256 recompensaComunidade = pergunta.recompensa * taxaDaComunidade / 100;

        respostas[_perguntaId][melhorRespostaId].autor.transfer(recompensaComunidade);

        expirarPergunta(_perguntaId);
    }
}
