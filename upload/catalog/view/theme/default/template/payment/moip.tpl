<?php
/**
 * Módulo Moip Transparente
 *
 * @Autores: Valdeir Santana <valdeirpsr@hotmail.com.br>
 *           Glauco <csakaos@hotmail.com>
 *           Manoel Vidal <email@email.com>
 * 
 * @version 1.0.0
 * @license <a href="http://www.opensource.org/licenses/bsd-license.php">BSD License</a>
 */
?>
<style>
	#cartaoCredito .checkout-heading, #debito .checkout-heading, #pagarBoleto .checkout-heading {cursor:pointer;}
	#erro, #sucesso {display:none;}
</style>
<?php
	/* Inicio do tratamento */
	if(!isset($fretegratis)){ 
		if(isset($this->session->data['shipping_method'])){
			$valorfe = preg_replace("/[^0-9]/", "", $this->session->data['shipping_method']['text']);
			if($this->session->data['shipping_method']['code']!='free.free'){
				if($valorfe<1){
					$errofrete=true;
				}
			}
		} else {
			$valorfe=0;
		}
	} else if($fretegratis==true){
		$valorfe=0;
	}
	$zip = preg_replace("/[^0-9]/", "",$zip);
	if(!isset($numero)){
		$numero="0";
	}
	if(!isset($bairro)){
		$bairro="";
	}
	if(!isset($ddd)){
		$ddd="00";
	}
	if(!isset($address2) || empty($address2)){
		$address2="Desconhecido";
	}
?>

<?php
	/* Dados dos produtos */
	$descicaaao="";
	$valortotalpdedido=0;
	$pesodetodososprodutos=0;

	foreach ($products as $product) {
		if (!isset($product['disconto'])) {
			$preco = $product['valor'];
		} else {
			$preco = $product['disconto'];
		}
		$preco = preg_replace("/[^0-9]/", "", $preco);
		$preco = $preco*$product['quantidade'];
		$pesoprod = preg_replace("/[^0-9]/", "", $product['peso']);
		$descricaoproduto = $product['descricao'];
		$valortotalpdedido=$valortotalpdedido+$preco;
		$descicaaao.='Produto: '.$descricaoproduto.' Qtd: '.$product['quantidade'].' ';
		$pesodetodososprodutos=$pesodetodososprodutos+$pesoprod;
	}

	if(isset($cupondedesconto)){
		if($cupondedesconto>0){
			$cupondedesconto = preg_replace("/[^0-9]/", "", $cupondedesconto);
			$cupooooonddesconto=$cupondedesconto;
			$valortotalpdedido=$valortotalpdedido-$cupooooonddesconto;
		}
	}
	
	if(!isset($errofrete)){
		$valortotalpdedido=$valortotalpdedido+$valorfe;
	}
?>
<br />

<?php

	function ColocarPonto($valor){
		if(strlen($valor)>2){
			$n=strlen($valor)-2;
			$teste=substr($valor,0,$n).".".substr($valor,$n);
			return $teste;
		}else{
			return $valor;
		}
	}

	function FormataCep($cep){
		return substr($cep,0,5).'-'.substr($cep,5);
	}
	
	function FormataTelefone($ddd,$tel){
		return "(".$ddd.")".substr($tel,0,4).'-'.substr($tel,4);
	}
	
	// Coloca ponto no valor total do pedido
	$total= ColocarPonto($valortotalpdedido);
	// Formata o CEP
	$cep= FormataCep($zip);
	// Formata o número de telefone
	$dddtelefone= FormataTelefone($ddd,$telephone);
	// Remove Acentos do Logadouro
	$endereco= htmlentities($address1, ENT_QUOTES);
	// Remove Acentos do Bairro
	$endereco2= htmlentities($address2, ENT_QUOTES);
	// Remove Acentos do Cidade
	$cidade= htmlentities($city, ENT_QUOTES);
	// Remove Acentos do Nome
	$nome=htmlentities($first_name, ENT_QUOTES).' '.htmlentities($last_name, ENT_QUOTES);
	
	// Inicia cURL
	$ch = curl_init();

	$header[] = "Authorization: Basic " . base64_encode($apitoken.':'.$apikey);
		
	// Seta opçoes e parâmetro
	$options = array(CURLOPT_URL => $action,
		CURLOPT_HTTPHEADER => $header,
		CURLOPT_SSL_VERIFYPEER => false,
		CURLOPT_POST => true,
		CURLOPT_POSTFIELDS => utf8_encode('
			<EnviarInstrucao>
				<InstrucaoUnica TipoValidacao="Transparente">
					<Razao>'.$nometranzacao.'</Razao>
					<Valores>
						<Valor moeda="BRL">'.$total.'</Valor>
					</Valores>
					<IdProprio>'.$codipedido.'</IdProprio>
					<Pagador>
						<Nome>'.$nome.'</Nome>
						<Email>'.$email.'</Email>
						<IdPagador>'.$codipedido.'</IdPagador>
						<EnderecoCobranca>
							<Logradouro>'.$endereco.'</Logradouro>
							<Numero>'.$numero.'</Numero>
							<Complemento>Desconhecido</Complemento>
							<Bairro>'.$endereco2.'</Bairro>
							<Cidade>'.$cidade.'</Cidade>
							<Estado>'.strtoupper($estado).'</Estado>
							<Pais>BRA</Pais>
							<CEP>'.$cep.'</CEP>
							<TelefoneFixo>'.$dddtelefone.'</TelefoneFixo>
						</EnderecoCobranca>
					</Pagador>
					<Parcelamentos>
						<Parcelamento>
							<MinimoParcelas>2</MinimoParcelas>
							<MaximoParcelas>12</MaximoParcelas>
						</Parcelamento>
					</Parcelamentos>
				</InstrucaoUnica>
			</EnviarInstrucao>'),
		CURLOPT_RETURNTRANSFER => true
	);
	curl_setopt_array($ch, $options);
	
	// Executa cURL
	$response = curl_exec($ch);
	
	// Fecha coneçao cURL
	curl_close($ch);
	
	// Transforma string em elemento XML
	$xml = simplexml_load_string($response);
	
	// Acessa XML e pega "Token de Pagamento"
	$payment_token = $xml->Resposta->Token;
?>

<!-- Tipo de Pagamento -->
<input type="hidden" name="tipoPagamento" value="" />
<br />

<div class="warning" id="erro"> ERRO Token de Segurança </div>
<div class="success" id="sucesso"> Sucesso </div>
<br />

<div id="cartaoCredito">
	<div class="checkout-heading" alt="cartaoCredito">
		Pagar Com Cartão de Crédito
	</div>
	<div class="checkout-content" style="display:block;">
		<!-- Formas de Pagamento -->
		<table>           
			   <tr>
				   <!-- American Express -->
				   <td><img src="image/moip/cartaoCredito/1.jpg"/></td>
				   <!-- Diners -->
				   <td><img src="image/moip/cartaoCredito/2.jpg"/></td>
				   <!-- Hipercard -->
				   <td><img src="image/moip/cartaoCredito/3.jpg"/></td>
				   <!-- Mastercard -->
				   <td><img src="image/moip/cartaoCredito/4.jpg"/></td>
				   <!-- Visa -->
				   <td><img src="image/moip/cartaoCredito/5.jpg"/></td>
			   </tr>
			   <tr align="center">
				   <!-- American Express -->
				   <td><input type="radio" name="pgtipo" value="AmericanExpress" /></td>
				   <!-- Diners -->
				   <td><input type="radio" name="pgtipo" value="Diners" /></td>
				   <!-- Hipercard -->
				   <td><input type="radio" name="pgtipo" value="Hipercard" /></td>
				   <!-- Mastercard -->
				   <td><input type="radio" name="pgtipo" value="Mastercard" /></td>
				   <!-- Visa -->
				   <td><input type="radio" name="pgtipo" value="Visa" /></td>
			   </tr>
			   <br/>
			</table>

			<!-- Dados do Cartão / Inicio -->
			<div id="optCartao" style="display:none;margin-top:50px;">
				<table>
					<!-- Número do Cartão -->
					<tr>
						<td>
							Nome:
							<span class="help">Conforme escrito no cartão</span>
						</td>
						<td>
							<input type="text" name="nomeTitularCartao" alt="Nome do Titular do Cartão" value="<?php echo $nome ?>" />
							<span class='error' name='erroNomeTitular'></span>
						</td>
					</tr>
					<!-- Número do Cartão -->
					<tr>
						<td>
							Número do cartão:
							<span class="help">Apenas números</span>
						</td>
						<td>
							<input type="text" name="numeroCartao" alt="Número do Cartão" />
							<span class='error' name='erroCartaoDeCredito'></span>
						</td>
					</tr>
					<!-- Validade -->
					<tr>
						<td>
							Validade
							<span class="help">Apenas números</span>
						</td>
						<td>
							<input type="text" name="validadeCartao" alt="Validade do Cartão" />
							<span class='error' name='validadeCartaoCredito'></span>
						</td>
					</tr>
					<!-- Código de Segurança -->
					<tr>
						<td>
							Código de Segurança:
							<span class="help">Apenas números</span>
						</td>
						<td>
							<input type="text" name="codSegurancaCartao" alt="Código de Segurança do Cartão"/>
							<span class='error' name='erroCodSeguranca'></span>
						</td>
					</tr>
					<!-- Data de Nascimento -->
					<tr>
						<td>
							Data de nascimento:
							<span class="help">Apenas números</span>
						</td>
						<td>
							<input type="text" name="datanascimento" alt="Data de Nascimento" />
							<span class='error' name='erroDataNascimento'></span>
						</td>
					</tr>
					<!-- Telefone -->
					<tr>
						<td>
							Telefone:
							<span class="help">Apenas números</span>
						</td>
						<td>
							<input type="text" name="telefone" alt="Telefone para Contato" value="<?php echo $dddtelefone ?>" />
							<span class='error' name='erroTelefone'></span>
						</td>
					</tr>
					<!-- Número de CPF -->
					<tr>
						<td>
							Nº CPF':
							<span class="help">Apenas números</span>
						</td>
						<td>
							<input type="text" name="CPF" alt="Número de CPF do Titular" />
							<span class='error' name='erroCPF'></span>
						</td>
					</tr>
					<!-- Parcelas -->
					<tr>
						<td>Desejo dividi em: </td>
						<td>
							<select id="parcelas_valorTotal" style="display:none;"></select>
							<span class='error' name='erroParcelas'></span>
						</td>
					</tr>
					<tr>
						<td>
							<a onClick="Pagar();"><img src="image/moip/pagar_moip.png" alt="Pagar" /></a>
						</td>
					</tr>
				</table>
			</div>
			<!-- Dados do Cartão / Fim -->
		</div>
</div>

<div id="pagarBoleto">
	<div class="checkout-heading" alt="pagarBoleto">
		Pagar Com Boleto
	</div>
	<div class="checkout-content">
		<!-- Botão Pagar -->
		<a onClick="processaPagtoBoleto();"><img src="image/moip/pagar_moip.png" alt="Pagar" /></a>
	</div>
</div>

<div id="debito">
	<div class="checkout-heading" alt="debito">
		Pagar Com Débito em Conta
	</div>
	<div class="checkout-content">
		<!-- Formas de Pagamento -->
		<table>           
			<tr>
				<!-- Banco do Brasil -->
				<td><img src="image/moip/debito/6.jpg"/></td>
				<!-- Bradesco -->
				<td><img src="image/moip/debito/7.jpg"/></td>
				<!-- Banrisul -->
				<td><img src="image/moip/debito/8.jpg"/></td>
				<!-- Itaú -->
				<td><img src="image/moip/debito/9.gif"/></td>
		   </tr>
		   <tr align="center">
				<!-- Banco do Brasil -->
				<td><input type="radio" name="pgDebito" value="BancoDoBrasil" /></td>
				<!-- Bradesco -->
				<td><input type="radio" name="pgDebito" value="Bradesco" /></td>
				<!-- Banrisul -->
				<td><input type="radio" name="pgDebito" value="Banrisul" /></td>
				<!-- Itaú -->
				<td><input type="radio" name="pgDebito" value="Itau" /></td>       
			</tr>
			<!-- Botão Pagar -->
			<tr >
				<td colspan="4"><a onClick="processaPagtoDebito();"><img src="image/moip/pagar_moip.png" alt="Pagar" /></a></td>
			</tr>
		   <br/>
		</table>
	</div>
</div>


<div id="MoipWidget" data-token="<?php echo $payment_token; ?>" callback-method-success="funcao_sucesso" callback-method-error="funcao_falha"></div>

<script type="text/javascript" src="catalog/view/javascript/jquery.meio.mask.js"></script>
<script type='text/javascript' src="<?php echo $actionJson; ?>"></script>
<script type="text/javascript">
$.event.props = $.event.props.join('|').replace('layerX|layerY|', '').split('|');

$(function () {
	
	//Mascara - Número de Cartão
	$('input[name="numeroCartao"]').setMask({
		mask:'9999 9999 9999 9999 99',
		onValid: function () {
			$(this).css('background','#EAF7D9');
			$('span[name="erroCartaoDeCredito"]').empty().hide();
		},
		onInvalid: function () {
			$(this).css('background','#FFD1D1');
			$('span[name="erroCartaoDeCredito"]').text('Digite somente números').show();
		}
	});
	
	//Mascara - Validade do Cartão
	$('input[name="validadeCartao"]').setMask({
		mask:'19/99',
		onValid: function () {
			$(this).css('background','#EAF7D9');
			$('span[name="validadeCartaoCredito"]').empty().hide();
		},
		onInvalid: function () {
			$(this).css('background','#FFD1D1');
			$('span[name="validadeCartaoCredito"]').text('Data Inválida').show();
		}
	});
	
	//Mascara - Codigo de Segurança do Cartão
	$('input[name="codSegurancaCartao"]').setMask({
		mask:'9',
		type:'repeat',
		maxLength:4,
		onValid: function () {
			$(this).css('background','#EAF7D9');
			$('span[name="erroCodSeguranca"]').empty().hide();
		},
		onInvalid: function () {
			$(this).css('background','#FFD1D1');
			$('span[name="erroCodSeguranca"]').text('Código de Segurança Inválido').show();
		}
	});
	
	//Mascara - Data de Nascimento
	$('input[name="datanascimento"]').setMask({
		mask:'39/19/9999',
		onValid: function () {
			$(this).css('background','#EAF7D9');
			$('span[name="erroDataNascimento"]').empty().hide();
		},
		onInvalid: function () {
			$(this).css('background','#FFD1D1');
			$('span[name="erroDataNascimento"]').text('Data Inválida').show();
		}
	});
	
	//Mascara - Telefone
	$('input[name="telefone"]').setMask({
		mask:'(99)9999-9999',
		onValid: function () {
			$(this).css('background','#EAF7D9');
			$('span[name="erroTelefone"]').empty().hide();
		},
		onInvalid: function () {
			$(this).css('background','#FFD1D1');
			$('span[name="erroTelefone"]').text('Número Inválido').show();
		}
	});
	
	//Mascara - CPF
	$('input[name="CPF"]').setMask({
		mask:'999.999.999-99',
		onValid: function () {
			$(this).css('background','#EAF7D9');
			$('span[name="erroCPF"]').empty().hide();
		},
		onInvalid: function () {
			$(this).css('background','#FFD1D1');
			$('span[name="erroCPF"]').text('Número Inválido').show();
		}
	});
	
	//Cartão de Credito
	$('#cartaoCredito .checkout-heading').click(function () {
		$('#pagarBoleto, #debito').find('.checkout-content').slideUp('slow');
		$('#cartaoCredito').find('.checkout-content').slideDown('slow');
	});
	
	//Boleto
	$('#pagarBoleto .checkout-heading').click(function () {
		$('#cartaoCredito, #debito').find('.checkout-content').slideUp('slow');
		$('#pagarBoleto').find('.checkout-content').slideDown('slow');
		$('input[name="tipoPagamento"]').val('boleto');
	});
	
	//Debito
	$('#debito .checkout-heading').click(function () {
		$('#cartaoCredito, #pagarBoleto').find('.checkout-content').slideUp('slow');
		$('#debito').find('.checkout-content').slideDown('slow');
		$('input[name="tipoPagamento"]').val('debito');
	});
	
	//Exibi formulario de preenchimento do cartão
	$("input[name='pgtipo']").bind("click", function () {          
		$('#optCartao').show('slow');  
		$('#parcelas_valorTotal').show();
		CalcularParcelamento();
    });
});
</script>

<script type="text/javascript" ><!--
	// Função para calcular parcelamento
	function CalcularParcelamento() {
		var settings = {
			cofre: "",
			instituicao: $('input:radio[name="pgtipo"]:checked').val(),
			callback: "retornoCalculoParcelamento"
		};
			MoipUtil.calcularParcela(settings);
	};
    
	// Função que retorna os valores do parcelamento
    retornoCalculoParcelamento = function(data) {
		$('#parcelas_valorTotal').empty();        
        for(var i=0;i<data.parcelas.length;i++){
            if(i == 0){
				$('#parcelas_valorTotal').append('<option value="1" data-recebimento="AVista">'+'R$'+ data.parcelas[i].valor.replace(".",",")+ ' &agrave; vista </option>');   			
				$('#parcelas_valorTotal').append("</br>");
            }else{
				$('#parcelas_valorTotal').append('<option value='+data.parcelas[i].quantidade+' data-recebimento="Parcelado">'+ data.parcelas[i].quantidade+" parcelas de R$"+ data.parcelas[i].valor.replace(".",",") + " ao m&ecirc;s </option>");
				$('#parcelas_valorTotal').append("</br>");
            }
		}
    
    };
 --></script>   

<script type="text/javascript">
 
	// Função pagar com cartão de crédito
	function Pagar() {
	
		var settings = {
            "Forma": "CartaoCredito",
            "Instituicao": $('input:radio[name="pgtipo"]:checked').val(),
            "Parcelas": $('#parcelas_valorTotal').val(),
            "Recebimento": $('#parcelas_valorTotal').attr('data-recebimento'),
            "CartaoCredito": {
                "Numero": $('input[name="numeroCartao"]').val(),
                "Expiracao": $('input[name="validadeCartao"]').val(),
                "CodigoSeguranca":$('input[name="codSegurancaCartao"]').val(),
                "Portador": {
                    "Nome": $('input[name="nomeTitularCartao"]').val(),
                    "DataNascimento": $('input[name="datanascimento"]').val(),
                    "Telefone": $('input[name="telefone"]').val(),
                    "Identidade": $('input[name="CPF"]').val()
                }
            }
        }
		$('input[name="tipoPagamento"]').val('CartaoCredito');
        MoipWidget(settings);
    }
	
	// FUNÇAO DE CALLBACK PARA SUCESSO
	var funcao_sucesso = function(data){
		
		var tipoPagamento = $('input[name="tipoPagamento"]').val();
		$('#sucesso').empty().hide();
		
		//Verifica se é tipo boleto ou debito
		if (tipoPagamento == 'boleto') { //Caso seja boleto, exibe em um modal o boleto
			$.colorbox({
				iframe:true,
				open:true,
				href:data.url,
				innerWidth:'90%',
				innerHeight:'90%'
			});
		}else if(tipoPagamento == 'debito'){ //Caso seja debito, abre um popup
			popDebito = window.open(data.url);
			$('#sucesso').append('Habilite seu PopUp do navegador.<br/>');
		}
		
		//Verifica o tipo de pagamento e Cria mensagem de sucesso
		if (tipoPagamento == 'boleto' || tipoPagamento == 'debito') {
			mensagem_sucesso = '<i>Sua transação foi processada pelo <u><a href="https://www.moip.com.br/">Moip Pagamentos S/A</a></u>.<br/>Caso tenha alguma dúvida referente a transação, entre em contato com o Moip.</i>';
		}else{
			mensagem_sucesso = '<i>Sua transação foi processada pelo <u><a href="https://www.moip.com.br/">Moip Pagamentos S/A</a></u>. <br/>A sua transação está <b>"'+data.Status+'"</b> e o código Moip é <b>"'+data.CodigoMoIP+'"</b>.<br/>Caso tenha alguma dúvida referente a transação, entre em contato com o Moip.</i>';
		}
		
		//Esconde as opções de Cartão, Boleto e Debito
		$('#pagarBoleto, #debito, #cartaoCredito').find('.checkout-content').slideUp('slow');
		
		//Exibi mensagem de sucesso
		$('#sucesso').append(mensagem_sucesso);
		$('#sucesso').show('slow');
		
		//Adiciona pedido na loja
		$.ajax({
			type: 'GET',
			url: 'index.php?route=payment/moip/confirm',
			beforeSend: function() {
				$('#button-confirm').attr('disabled', true),
				$('#payment').before('<div class="attention"><img src="catalog/view/theme/default/image/loading.gif" alt="" /> Finalizando Pedido')
			},
			success: function() {
				$('#payment').submit();
			}
		});
	};
           
	// FUNÇAO DE CALLBACK PARA FALHA
	var funcao_falha = function(data) {
		$('#erro').empty();
		$('#sucesso').empty().hide();
		for(var i=0;i<data.length;i++){
			
			if (data[i].Codigo == 902) {
				$('span[name="erroParcelas"]').html('Informe a quantidade de parcelas').show();
			}
			
			if (data[i].Codigo == 905) {
				$('span[name="erroCartaoDeCredito"]').html('Número de cartão inválido').show();
			}
			
			if (data[i].Codigo == 906) {
				$('span[name="validadeCartaoCredito"]').html('Data de expiração deve estar no formato \'MM/AA\'').show();
			}
			
			if (data[i].Codigo == 907) {
				$('span[name="erroCodSeguranca"]').html('Informe o código de segurança do cartão').show();
			}
			
			if (data[i].Codigo == 909) {
				$('span[name="erroNomeTitular"]').html('Informe o nome do portador como está no cartão').show();
			}
			
			if (data[i].Codigo == 910) {
				$('span[name="erroDataNascimento"]').html('Data de nascimento do portador deve estar no formato DD/MM/AAAA').show();
			}
			
			if (data[i].Codigo == 911) {
				$('span[name="erroTelefone"]').html('Informe o telefone do portador').show();
			}
			
			if (data[i].Codigo == 912) {
				$('span[name="erroCPF"]').html('O CPF do portador inválido').show();
			}
			
			if (data[i].Codigo == 914) {
				$('#erro').html('Informe o token da Instrução').show();
			}
			
		}
		
	};
	
	// Função para pagamento via Debito
	function processaPagtoDebito() {
		var settings = {
            "Forma": "DebitoBancario",
            "Instituicao": $('input[name="pgDebito"]:checked').val()
        }
		 $('input[name="tipoPagamento"]').val('debito');  
        MoipWidget(settings);
    }
     
	// Função para pagamento via Boleto
    function processaPagtoBoleto() {
        var settings = {
            "Forma": "BoletoBancario"
        }
		$('input[name="tipoPagamento"]').val('boleto');
        MoipWidget(settings);
    }
</script>