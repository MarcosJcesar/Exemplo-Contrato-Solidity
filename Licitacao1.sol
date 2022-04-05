// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//**********************************************************************************************////
//inicio do contrato
contract Licitacao {
    // Abaixo temos alocação de memória para gravar o nome da instituição que vai criar o contrato
    string instituicaoDonaDaLicitacao; 
    // Abaixo temos Alocação de memória para gravar o endereço da contada instituição que vai criar o contrato
    address contaDaInstituicaoGovernamental; 
    // Alocação de memória para gravar o numero de lances
    uint contadorDeLances = 0; 
    /* Alocação de memória para gravar um indicador que nos diz se a empresa que está interagindo com
     contrato está cadastrada no mesmo */
    bool seEmpresaEstaCadastrada = false;
    // Alocaçao na memória para uma variável que servirá de controle para o cadastro, ela inicia com valor false
    // false significa que o valor da variável é inicialmente falso
    bool fazerCadastro = false; 
    // Vai receber a timestamp da implantacao do contrato
    uint inicioDosCadastrosDaLicitacao;  
    // Essa é espaço na memoria que vai gravar se a empresa deseja alterar o lance
    bool alterarLanceSimOuNao=false;
    // Controle de chamada
    //bool controleDeChamada=false; 
    string empresaNomeDeMenorLance=""; // <- Grava o nome da empresa que possui o menor lance toda vez ele mudar
    uint valorLanceMenor=0; // <- Grava o valor de menor lance toda vez que ele muda
    // Cria um estrutura na memoria para receber os dados de cada empresa
    struct Empresa {
        string nomeFantasia; // <- Grava o nome fantasia solicitante no cadastro
        uint cnpj; // <- Grava o CNPJ da empresa solicitante no cadastro
        address enderecoDaConta; // Endereço da conta no blockchain
        uint valorLanceDaEmpresa; //Se tem algum lance (Valor)
        uint ultimaAlteracaoNoLance; // Esse é um espaço alocado na memória para gravar o último lance menor
    }
    //Cria um vetor para armazenar todas as empresas como em uma lista
    Empresa[] listaDeEmpresas; // <- Grava as empresas cadastradas em uma lista
    Empresa empresaCadastrada; // <- Cria a estrutura definida a cima para receber os dados das empresas
    
//**********************************************************************************************////
    //O bloco abaixo é o bloco inicial que dá origem ao contrato no blockchain
    //bloco de texto responsável por criar (gravar, implantar) o contrato no blockchain
    //esse bloco vai determinar que o dono do contrato (dono da licitação é o conta que criou ou melhor a conta que enviou o contrato para o blockchain
    constructor(string memory _instituicao) {
        require(msg.sender==0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        unicode"Essa não é conta da Instuição para esse contrato");
        // A linha abaixo verifica se na hora na criação a instituição colocou seu nome no contrato
        // caso contrário o contrato não será gravado no blockchain, e será cobrada somente a taxa de gas
        // que deu origem a solicitação.
        require(keccak256(abi.encodePacked(_instituicao)) != keccak256(abi.encodePacked("")), unicode"É necessário a indentificação da instituição para implantar esse contrato");
        // Grava o nome enviado na variável instituicaoDonaDaLicitacao
        instituicaoDonaDaLicitacao = _instituicao;
        //Grava o endereço da conta que deu origem ao envio do contrato na variável contaDaInstituicaoGovernamental
        contaDaInstituicaoGovernamental = msg.sender;
        // Gravar o inicio do contrato
        inicioDosCadastrosDaLicitacao = block.timestamp;
    }
//**********************************************************************************************////


//**********************************************************************************************////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //Bloco de texto chamado função que diz para quem chama-lo quem é o dono da licitação (contrato)
    function quemEADonaDessaLicitacao() public view returns(string memory _instituicao,address _contaInstituicao){
        return (instituicaoDonaDaLicitacao,
        contaDaInstituicaoGovernamental);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////
//**********************************************************************************************////



//**********************************************************************************************////
    //Embora o nome de função seja "cadastroDeEmpresas", ela faz muito mais que isso como se poder ver
    //Bloco de texto responsável pelo cadastro das empresas licitantes
    function cadastroDeEmpresas(string memory _nomeFantasia, uint _cnpj) public {
        // quando temos um require, significa que o para o que o código possa ser
        // executado ele precisa atender o que require pede.
        // nesse cado o require exige que o tempo atual seja menor que 10 minutos
        // para que as empresas possam se cadastrar
        // caso contrário ele envia a mensagem "O tempo de 10 minuto para fazer o cadastro já terminou"
        require(block.timestamp <= inicioDosCadastrosDaLicitacao + 10 minutes,
        unicode"O tempo de 10 minuto para fazer o cadastro já terminou");
        // Requer que a conta que esteja fazendo o cadastro para participar da licitação
        // Não seja a conta que dona do contrato (Não seja a conta da instiuição)
        require(msg.sender!=contaDaInstituicaoGovernamental,
        unicode"A instituição dona do contrato não pode participar da licitação");
        // Requer que o nome fantasia não seja em branco
        require(keccak256(abi.encodePacked(_nomeFantasia)) != keccak256(abi.encodePacked()),
        unicode"É necessário enviar o nome fantasia");
        // Requer que o CNPJ não seja em branco
        require(keccak256(abi.encodePacked(_cnpj)) != keccak256(abi.encodePacked("")),
        unicode"É necessário enviar o CNPJ");
        // Requer que o CNPJ não um número seja zero
        require(_cnpj != 0, unicode"É necessário enviar o CNPJ");
        // Requer que o CNPJ um texto zero
        require(keccak256(abi.encodePacked(_cnpj)) != keccak256(abi.encodePacked("0")),
        unicode"É necessário enviar o CNPJ");
        //
        fazerCadastro=true; // Caso os dados estejam preenchido continua o cadastro
        seEmpresaEstaCadastrada = false; // Parte do princípio que a empresa não está cadastrada
        empresaVerificaSeEstaCadastrada(); // Executa verificação se empresa já está cadastrada
        //A linha abaixo desse bloco informa que para que o código possa prosseguir
        //a verificação acima "empresaVerificaSeEstaCadastrada()" deve retornar um valor false (falso)
        require (seEmpresaEstaCadastrada == false, unicode"Está conta já tem um cadastrado feito");
        //Caso o cadastro anterior da empresa for falso, ou seja a empresa ainda não está cadastrada
        //então tenta-se cadastra a empresa usando as linhas de código abaixo desse bloco de texto
        //verificando se o CNPJ já está cadastrado em outra conta
        conferirCadastroEmpresa(_cnpj,0);
        //Caso o CNPJ já esteja cadastrado, o cadastro para por aqui,
        require (seEmpresaEstaCadastrada == false, unicode"Este CNPJ já está participando da licitação");
        //caso contrário o cadastro continua
        //***************************************************************/
        //Tudo certo então o cadastro é feito para participar da licitacao
        //***************************************************************/
        // Esse bloco abaixo grava o nome fantasia da empresa, o CNPJ, o endereço da conta
        // o valor do lance no primeiro momento é zero
        // e o valor do tempo do lance no primeiro momento também é zero
        // já que não houve lance
        // "Empresa memory novaEmpresaParticipa" cria-se uma variável que receber os dados da empresa
        Empresa memory novaEmpresaParticipa = Empresa(_nomeFantasia, _cnpj, msg.sender, 0, 0);
        // listaDeEmpresas é o variável que server de lista, criada no inicio do contrato para
        // receber as empreas cadastradas
        listaDeEmpresas.push(novaEmpresaParticipa); // push é um comando que grava a empresa na lista
    }
//**********************************************************************************************////
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    //Verifica se empresa está casdastrada na hora que a mesma vai fazer o seu devido cadastro ou
    //quando a mesma solicita através da sua conta
    function empresaVerificaSeEstaCadastrada() public 
    returns( // toda vez que encotramos a palavra "returns" isso indica uma obrigação de retorno da função
        string memory _seCadastrado, // Nesse caso ele tem que retornar um valor texto
        //que é empresa cadastrada ou não)
        string memory nome, // o Nome da empresa, se não cadastrada retorna
        //"Não há nenhum nome cadastrado até o momento"
        uint cnpj, uint lanceDaEmpresa) // Retorna CNPJ, Lance, caso não encontrado esse valor são 0 (zeros)
        {
        if(fazerCadastro==false){ // Verifica se a váriavel "fazerCadastro" é de valor falso
            // caso o valor seja falso então não existe solicitação de cadastro no momento
            // e sim uma solicitação somente de pesquisa para saber se empresa está casdastrada
            if(listaDeEmpresas.length == 0){ // Verifica se a lista está vazia
                // Se a lista está vazia quer dizer que não existe cadastro nenhum
                // então abaixo é criada então uma variável que vai informar que não existem empresas cadastradas
                string memory naoTemCadastro = unicode" No momento não existe nehuma empresa cadastrada";
                // Também é criada uma variável que informa que não existe um nome fantasia
                string memory naoTemNome = unicode" Não há nenhum nome cadastrado até o momento";
                uint naoHaCNPJ = 0; // o CNPJ é zero
                uint naoHaLanceDaEmpresa = 0; // o Lance é zero
                // Organiza tudo dentro dos parenteses como determinado no inicio da chamada da função
                // e envia finalizando a execução da função por aqui
                return (naoTemCadastro, naoTemNome, naoHaCNPJ, naoHaLanceDaEmpresa);
            }
        }
        conferirCadastroEmpresa(0,0); // Chama outra função que é a função conferirCadastroEmpresa(0,0)
        // os valores 0 (zeros) passado entre parenteses significa para a função conferirCadastroEmpresa(0,0)
        // que ela não vai conferir esses valores e sim o somente se a conta que solicitou o contrato
        // está casdastrada, ele faz isso usando apenas o msg.sender que é o endereço da conta.
        // a função conferirCadastroEmpresa(0,0) que foi chamada retorna um valor verdadeiro ou falso
        // seEmpresaEstaCadastrada=true é verdadeiro, a empresa está castradada
        // seEmpresaEstaCadastrada=false é falso, a empresa não está cadastrada
        if(seEmpresaEstaCadastrada==true){ // No caso se esse função atual recebe seEmpresaEstaCadastrada=true
            // a empresa está cadastrada, então ele retorna os dados abaixo e finaliza sua execução
            return (unicode" Essa conta já está cadastrada",
            empresaCadastrada.nomeFantasia, // Nome fantasia
            empresaCadastrada.cnpj, // CNPJ
            empresaCadastrada.valorLanceDaEmpresa // Valor do lance da empresa
            );
        }
        // Caso nenhuma das condições acima seja verdadeira, o código chegou à essa linha
        // E foi concluído que a conta em questão que solicitou a interação com o contrato
        // Não está cadastrada
        return (unicode" Essa conta não está cadastrada", // <- então retorna-se essa mensagem
        unicode"Nome não encontrado", // e também retorna nome fantasia não encontrado
        0, // CNPJ zero
        0); // Tempo do último lance zero
    }
    ///**********************************************************************************************///
    //Esse block abaixo da linha 186 até a linha xxxx confere se a conta em questão está cadastrada para concorrer a licitação
    //Além de conferir se o CNPJ está cadastrado quando solicitado
    //Também uma continuição da função acima que passa o CNJP como zero
    //Ele é chamado tanto pela função acima quando também pode ser chamando semparadamente
    //Sempre recebe um CNPJ para conferir se este existe já no contrato
    //Caso a ideia não seja conferir o CNPJ ao chama-la esse deve ser passado como zero, pois não existe CNJP
    //Cadastrado como zero, já que o próprio contrato barra o cadastro de CNPJ com valor zero.
    ///**********************************************************************************************///
    function conferirCadastroEmpresa(uint verificarCNPJ, uint lance)
    internal // <- indica que essa é uma função que só pode ser chamada internamente, ou seja por esse contrato
    returns(
        Empresa memory _empresa, // retorna a empresa se essa está casdastrada
        bool cadastrada // retorna um valor de verdadeiro ou falso se cadastrada ou não cadastrada
        )
        { // inicio da função
        // Presume inicialmente que a empresa não está cadastrada para pesquisar se isso realmente é verdade
        // essa presunção é também uma segurança caso a variável "seEmpresaEstaCadastrada" esteja com o valor
        // verdadeiro vindo de alguma pesquisa anterior
        seEmpresaEstaCadastrada = false;
        // Na função abaixo o comando for vai fazer uma varedura na lista de empresas "listaDeEmpresas"
        for (uint i = 0; i < listaDeEmpresas.length; i++) {
            // cada empresa encontrada é colocada dentro de variável "empresaCadastrada"
            // isso é possível porque o valor i começa em zero e vai até o limite da lista
            // dessa forma o i=0 é a primeira empresa
            // o i é incrementado 1 cada fez que o for vai fazendo a varedura em ciclo
            // quer dizer que no primeiro ciclo é encotrada a empresa que está na possição zero
            // no segundo clico a empresa que está na possição 1, e assim por diante
            empresaCadastrada=listaDeEmpresas[i]; 
            if(msg.sender == empresaCadastrada.enderecoDaConta){ // conta empresa encontrada na lista
                if(alterarLanceSimOuNao==true){ // deseja alterar lance?
                        Empresa storage alterar = listaDeEmpresas[i]; // se sim
                        if(empresaCadastrada.ultimaAlteracaoNoLance!=0){ // verifica se deu algum lance
                            // se sim
                            uint tempo = empresaCadastrada.ultimaAlteracaoNoLance; // verifica hora o último lance
                            // requer que tenha passado 2 minutos depois de aceito o lance anterior
                            require(block.timestamp >= tempo + 2 minutes,
                            unicode"Você acabou de faze um lance, aguarde o tempo determinado de espera que é 2 minutos");
                        }   
                    if(valorLanceMenor==0){ // verifica que a empresa não deu nenhuem lance anterior
                        alterar.valorLanceDaEmpresa = lance; // altera o lance da empresa
                        alterar.ultimaAlteracaoNoLance = block.timestamp; // grava o tempo atual no lance da empresa
                        empresaCadastrada=alterar; // grava isso no registro struct da empresa
                        //empresasLance[empresaCadastrada.nomeFantasia]=lance;
                        valorLanceMenor=lance; // grava o lance alterado no registro da empresa
                        // Grava o nome da empresa na variável que indica qual é a empresa de menor lance
                        // no momento
                        empresaNomeDeMenorLance=listaDeEmpresas[i].nomeFantasia; 
                        // retorna os valores para que chamou a função
                        return (empresaCadastrada, seEmpresaEstaCadastrada=true);
                    } 
                    // Casao as condicões acima não seja verdadeiras (Não o primeiro lance, e também ja correu 2 minutos
                    // desde o último lance agora verifica-se se o lance é menor do que o último lance que está vencendo
                    // a licitação,
                    // se sim então o lance é aceito, caso contrário a empresa poderá fazer outro lance imeditamente
                    require(lance<valorLanceMenor,
                    unicode" Já Existe um lance feito anteriormente menor ou igual a esse valor, para vence-lo ofereça uma lance menor");
                    alterar.valorLanceDaEmpresa = lance; // Grava o lance em uma memória
                    alterar.ultimaAlteracaoNoLance = block.timestamp; // grava o tempo em uma memória
                    empresaCadastrada=alterar; // passa o que foi grava na memória para a o registro da empresa
                    // no contrato
                    //empresasLance[empresaCadastrada.nomeFantasia]=lance;
                    alterarLanceSimOuNao=false; // Deternima que a variável "alterarLanceSimOuNao" agora é false
                    // ou seja tem o valor falso para que agora ela possa ser usada por outra iteração
                    // caso seja chamada novamente
                    valorLanceMenor=lance; // Grava o menor lance na memória do contrato
                    empresaNomeDeMenorLance=alterar.nomeFantasia; // Grava a empresa que deu o menor lance
                    // na memória do contrato
                }
                // Retorna o resultado para quem chamou a função
                return (empresaCadastrada, seEmpresaEstaCadastrada=true);
            }
            // Esse código é excutado caso nenhuem dos outro acima dentro dessa função seja chamado
            // isso significa que o dispositivo que chamou a função deseja somente consulta um CNPJ
            // Nessa linha abaixo se for encontrada na lista uma empresa que tem o CNPJ procurado.
            // o código retornado é que sim, a empresa está cadastrada, já existe esse CNPJ no sistema do contrato
            // Isso é possível porque nesse momento o código ainda está dentro do loop do (clico) do comando for que está
            // varendo os dados da lista em busca de todos os dados das empresas cadastradas
            if(verificarCNPJ == empresaCadastrada.cnpj){
                // Se encontrado o CNPJ retorna os dados e finaliza a execução do for e da função "conferirCadastroEmpresa"
                return (empresaCadastrada, seEmpresaEstaCadastrada=true);
            }
        }
        // Caso não seja encontrada nehuma empresa no cadastro
        // cria-se uma empresa vazia pois a função é obrigada a retorna uma empresa qualquer
        // como não existe a empresa que estava sendo buscando cadastrada no contrato
        // essa empresa vai vazia, porém o resultado "seEmpresaEstaCadastrada" vai com valor falso
        // isso faz com que o resultado de empresa cadastrada seja falso
        // e a empresa vazia é ignorada pelo dispositivo que chamou a função
        Empresa memory naoExiteEmpresaCadastrada;
        empresaCadastrada=naoExiteEmpresaCadastrada;
        return (naoExiteEmpresaCadastrada, seEmpresaEstaCadastrada=false);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    ///**********************************************************************************************///
    ///     Retorna a lista com todas empresas cadastradas            //////////////////////////////////
    function verificaTodasASEmpresas() view public returns(Empresa[] memory _listaDeEmpresas) {
        return (listaDeEmpresas);
    }
///**********************************************************************************************///
 


///********************************* Hora de fazer o lance **************************************///
    function enviarLance(uint _lance) public
    returns(string memory nome, // Retrona o nome da empresa que deu o lance caso aceito
        uint lance // retorna o lance dado caso aceito
        )
        { // Inicio da função
        // Requer que o tempo seja maior que 10 minutos do inicio dos cadastros
        require (block.timestamp >= inicioDosCadastrosDaLicitacao + 10 minutes,
        unicode"Os lances ainda não iniciaram, aguarde");
        // Requer que o tempo seja menor que 23 minutos do inicio dos cadastos
        // o resutado é que será 13 minutos de lance
        require (block.timestamp <= inicioDosCadastrosDaLicitacao + 23 minutes,
        unicode"Os lances finalizaram");
        // Informa que o desejo da conta que está interagindo com contrato é alterar o lance
        alterarLanceSimOuNao=true;
        // Chama a função conferir cadastro que vai conferir o cadastro e alterar o lance
        // se tudo estiver nos conforme como visto anteriomente
        conferirCadastroEmpresa(0,_lance); // Nesse caso passa o CNPJ como zero pois não deseja conferir
        // o CNPJ, mais sim a conta e passa o valor so lance que entrou como paramentro 
        alterarLanceSimOuNao=false; // ao receber o resultado devolver o valor false para
        // a variável "alterarLanceSimOuNao" acima para que seja usada em outra interação possível
        require (seEmpresaEstaCadastrada == true, // Requer que "seEmpresaEstaCadastrada"  
        unicode"Empresa não está cadastrada para enviar lance"); // Contrário envia essa mensagem e finaliza o envio
        return (empresaCadastrada.nomeFantasia, empresaCadastrada.valorLanceDaEmpresa); // = _lance;
    }


///********************************* Hora de fazer o lance **************************************///
    function verificaMenorLance() view public returns(string memory _nomeEmpresa, uint _lanceEmpresa){
        return (empresaNomeDeMenorLance, valorLanceMenor);
    }
///********************************* Hora de fazer o lance **************************************///

}
