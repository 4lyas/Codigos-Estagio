# -*- coding: UTF-8 -*-

import yaml
import argparse
import bcrypt
import logging as log_app
import datetime as dt

from backup_oracle import *
from multiprocessing import Process, Queue, Pool

def initializer(file_log_name,log_lvl,formato_log,tipo_bkp):
	global log_app
	global tipo_backup
	global log_level
	
	tipo_backup = tipo_bkp
	log_level = log_lvl

	log_app.basicConfig(filename=file_log_name, level=log_level, format=formato_log)

def worker(sid):
	log_app.info('Iniciando Backup da instancia {}'.format(sid))
	bkp = backup_oracle(sid,tipo_backup)
	bkp.executa_backup(log_level)
	log_app.info('Backup da instancia {} concluido com sucesso'.format(sid))

if __name__ == '__main__':
	#Definição dos argumentos
	argp = argparse.ArgumentParser(description='Executa o backup (incremental,archivelog,full) via rman do banco de dados informado')
	argp_sel_sid = argp.add_mutually_exclusive_group(required=True)
	argp_sel_sid.add_argument('--sid', metavar='sid',  type=str, help = 'Instancia do banco de dados')
	argp_sel_sid.add_argument('--all', action = 'store_true', help = 'Seleciona todas as instancias do servidor')
	argp.add_argument('--tipo_backup', required=True, metavar='tipo', type=str, choices=['incremental', 'archivelog', 'full'], help = 'Tipo de backup')
	argp.add_argument('--tipo_log', required=True, metavar='tipo_log', type=str, choices=['INFO', 'DEBUG', 'WARNING', 'ERROR'], help = 'Tipo de backup')
	args = argp.parse_args()

	if args.sid is None:
		sid = ''
	else:
		#Convertendo SID para minusculo
		sid = (args.sid).lower()
	
	#Configurando padrão log
	switcher = {
		'INFO': log_app.INFO,
		'DEBUG': log_app.DEBUG,
		'WARNING': log_app.WARNING,
		'ERROR': log_app.ERROR,
	}
	log_level = switcher.get(args.tipo_log)
	
	#Configurando formato log
	formato_log = ' %(asctime)s - %(levelname)s - %(message)s'

	# Configurando o logger
	formato = (dt.datetime.now()).strftime("%Y-%m-%d-%H%M%S.%f")[:-3]
	file_log_name ='D:\\projeto\\log\\relatorio_backup_{}.log'.format(formato)
	log_app.basicConfig(filename=file_log_name, level=log_level, format=formato_log)
	
	#Convertendo tupla para lista
	lista_instancias = []
	for instancia in backup_oracle.obtem_lista_db(args.sid):
		lista_instancias.append(instancia[0])

	log_app.info("Inicando rotina de backup da(s) instancia(s):{}".format(lista_instancias))
	
	#Número de processos em paralelo
	NUMBER_OF_PROCESSES = 2

	# Submit tasks

	with Pool(NUMBER_OF_PROCESSES, initializer, (file_log_name,log_level,formato_log,args.tipo_backup)) as pool:
		pool.map(worker,lista_instancias)
	
	log_app.info('Fim da rotina de backup.')