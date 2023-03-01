#!/bin/bash

#Arquivo para realizar backup de arquivos ou diretórios dentro do SO linux

# Menu Principal que verificara se o usuario nao iniciou o arquivo por erro
MenuPrincipal(){
	echo "Realizar backup de diretórios e/ou arquivos?"
	echo "1 - Sim"
	echo "2 - Não. Sair"
	read fazerBackup
	case $fazerBackup in
		1) functionBackup ;;
		2) exit;;
		*) echo "Opção inexistente.";  MenuPrincipal ;;
	esac
}

# funcao de diretorio de destino para p backup
functionDiretorioDeDestino(){
	clear
	echo "Deseja realizar o backup no diretorio atual? (s/n)"
    read verificaBackupNoDiretorioAtual
    if [ $verificaBackupNoDiretorioAtual = "s" ]; then
		diretorioDeDestino=$(pwd)
        echo "Os arquivos irão para: $diretorioDeDestino"
    else
		echo "Digite o caminho (desde a raiz) do diretório de destino para backup:"
		read diretorioDeDestino
		if [ -d $diretorioDeDestino ]; then
			echo $diretorioDeDestino
		else
            until [ -d $diretorioDeDestino ]; do
				echo "Este diretório não existe. Digite novamente o caminho:"
                read diretorioDeDestino
            done
			echo "Os arquivos irão para: $diretorioDeDestino"
        fi
	fi
}

# funcao de diretorio de origem dos arquivos para backup
functionDiretorioDeOrigem() {
	clear
	echo "Fará backup do diretório atual? (s/n)"
	read confirmacaoDeOrigem
	if [ $confirmacaoDeOrigem = "s" ]; then
        diretorioDeOrigem=$(pwd)
        echo "Os arquivos irão para: $diretorioDeOrigem" 
    else
		echo "Digite o caminho (desde a raiz) do diretório de origem para backup:"
		read diretorioDeOrigem
        if [ -d $diretorioDeOrigem ]; then
            echo "diretório de origem: $diretorioDeOrigem"
		else
			until [ -d $diretorioDeOrigem ]; do
				echo "Este diretório não existe. Digite novamente o caminho:"
                read diretorioDeOrigem
			done
			echo "Os arquivos irão para: $diretorioDeOrigem"
        fi
    fi
}

# funcao de configuração do backup
functionConfigurarBackup(){
    clear
	echo "Deseja excluir subdiretórios vazios para a pasta de backup? (s/n)"
	read confirmaExclusaoDeSubdiretoriosVazios
	if [ $confirmaExclusaoDeSubdiretoriosVazios = "s" ]; then
		opcaoDeBackup="-hamP"
	else
		opcaoDeBackup="-haP"
	fi
	echo "Deseja excluir algum arquivo do backup? (s/n)"
	read confirmaExclusaoDeArquivos
	if [ $confirmaExclusaoDeArquivos = "s" ]; then
		echo "Escreva o nome dos arquivos e se existir mais de um arquivo os separe com vígula e espaço."
		echo "	Exemplo: arquivo1, arquivo2, arquivo3, ..., arquivoN"
		read arquivosAExcluirNoBackup
		opcaoDeBackup="$opcaoDeBackup --exclude=$arquivosAExcluirNoBackup"
	fi
}

# funcao que confirmara se o usuario deseja agendar o backup 
#  ou deixar como tarefa periodica
functionPeriodicidadeNosBackups() {
	clear
	echo "Deseja realizar backups com periodicidade, ou o deixar agendado? (s/n)"
	read opcaoDeControleDeTempo
	if [ $opcaoDeControleDeTempo = "s" ]; then
		functionCrontab ;
	else
		echo "Backup será realizado em breve"
	fi
}

# funcao que pegara o espaco de tempodo agendamento do backup
functionCrontab() {
	echo "Deseja realizar backups em dias da semana? (s/n)"
	read verificaDiasDaSemana
	if [ $verificaDiasDaSemana = "s" ]; then
        echo;
        echo "  Digite o dia da semana. Exemplo de digitação:"
        echo "  Para segunda, digite: 1"
        echo "  Para terça, digite: 2"
        echo "  ..."
        echo "  Para domingo, digite: 7"
        echo "  1, 2, 3"
        read diasDaSemana
	else
		diasDaSemana=*
	fi

	echo "Deseja realizar backups em dias do mês especifico? (s/n)"
	read verificaDiasDoMes
	if [ $verificaDiasDoMes = "s" ]; then
        echo;
        echo "  Digite o dia do mês (1, 2, 3, ..., 31)"
        read dia
	else
		dia=*
	fi

	echo "Deseja realizar backups em algum mês especifico? (s/n)"
	read verificaMes
	if [ $verificaMes = "s" ]; then
        echo;
        echo "  Digite o mês (1, 2, 3, ..., 12)"
        read mes
	else
		mes=*
	fi

	echo "Deseja realizar backups em algum horário especifico? (s/n)"
	read verificaHoras
	if [ $verificaHoras = "s" ]; then
        echo;
        echo "  Digite a hora e apenas a hora (0 a 23, meia-noite=0)"
        read h
        echo "  Digite os minutos (0 a 59)"
        read min
	else
		h=*
		min=*
	fi
	echo "Backup agendado para o/os dia/dias: $dia, do/dos mês/meses: $mes, às: $h:$min, do/dos dia/dias semanal/semanais $diasDaSemana"
}

# confirma se deseja continuar com o backup ou sair do programa
functionConfirmarBackup(){
    clear
	if [ ! $dia ]; then
		echo "Confirma backup do $diretorioDeOrigem para $diretorioDeDestino? (s/n)"
	else
		echo "Confirma backup do $diretorioDeOrigem para $diretorioDeDestino, agendado para dia: $dia, mês: $mes, dia da semana: $diasDaSemana, horário: $h:$min? (s/n)"
	fi
	read confirma
	if [ $confirma = "s" ] || [ $confirma = "S" ]; then
		echo "Backup sendo realizado..."
	else
		exit ;
	fi
}

# Realiza o backup
functionBackup(){
	clear
	dataDoBackup=$(date +%d-%m-%Y)
	functionDiretorioDeOrigem
	functionDiretorioDeDestino
	functionConfigurarBackup
	functionPeriodicidadeNosBackups
	functionConfirmarBackup
	pastaDeBackup="backup-$dataDoBackup"
	comandoBackup="rsync $opcaoDeBackup --backup --backup-dir=$pastaDeBackup $diretorioDeOrigem $diretorioDeDestino/$pastaDeBackup"
	if [ ! $dia ]; then
		$comandoBackup
	else
		(crontab -l; echo "$min $h $dia $mes $diasDaSemana $comandoBackup") | sort -u | crontab - 
		echo "Backup agendado para: "
		crontab -l
	fi
}

MenuPrincipal
