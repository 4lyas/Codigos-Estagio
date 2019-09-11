# -*- coding: UTF-8 -*-
#!/bin/python
#!/usr/bin/python
# export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/drives/c/oracle/instantclient_11_2/

import time
import random
import cx_Oracle
import logging as log_backup
import logging.config
import datetime as dt
import sys
import os

from jinja2 import Environment, FileSystemLoader

os.environ["ORACLE_HOME"] = "/opt/oracle/app/oracle/product/12.1.0/dbhome_1"
os.environ["LD_LIBRARY_PATH"] = "/opt/oracle/app/oracle/product/12.1.0/dbhome_1/lib"

class backup_oracle():
    # passa por parametro o tipo de backup e qual banco
    def __init__(self,sid,tipo_backup):
        self.sid = sid.lower()
        self.tipo_backup = tipo_backup.upper()
        
    def def_backup(self):
        if (self.tipo_backup == 'FULL'):
            self.backup_level = 0
            self.sectionsize = 'SECTION SIZE 25G'
            self.crosscheck = True
            self.archive = True

        elif (self.tipo_backup == 'INCREMENTAL'):
            self.backup_level = 1
            self.sectionsize = 'SECTION SIZE 25G'
            self.crosscheck = False
            self.archive = True

        elif (self.tipo_backup == 'ARCHIVELOG'):
            self.backup_level = 2
            self.sectionsize = 'SECTION SIZE 25G'
            self.crosscheck = False
            self.archive = False

    # obtem lista de databases a backupear
    @staticmethod
    def obtem_lista_db (sid):
        if sid is None:
            sid = '%'

        #TODO: REMOVER DEFAULT VALUE QUANDO PASSAR PARA PRD
        hostname = os.getenv('HOSTNAME','')
        
        sid_infra = ''
        user_infra = ''
        password_infra = ''
        
        connection = cx_Oracle.connect(user_infra, password_infra, sid_infra)
        cursor = connection.cursor()
        cursor.execute("select sid from ur_infra.bndes_instances where host = '{}' and backup = 'x' and sid like '{}'".format(hostname,sid))
        return cursor.fetchall()
    
    def obtem_data_ultimo_backup_full (sid):
        if sid is None:
            sid ='%'
        #TODO: TROCAR USUÁRIO PARA A MÁQUINA.
        hostname = os.getenv('HOSTNAME','')
        
        sid_infra = ''
        user_infra = ''
        password_infra = ''
        
        connection = cx_Oracle.connect(user_infra, password_infra, sid_infra)
        cursor = connection.cursor()
        cursor.execute("select to_char(max(rs.end_time),'YYYY-MM-DD HH24:MM:SS') as ULTIMO_FULL from V$RMAN_STATUS rs inner join (select distinct session_recid,backup_type,incremental_level from v$backup_set_details where backup_type in ('I') and incremental_level = 0) bt on rs.session_recid = bt.session_recid where rs.operation = 'BACKUP' and rs.status = 'COMPLETED' and rs.object_type in ('DB INCR') order by rs.start_time desc")
        return cursor.fetchall()
        
     

    def setup_logger(self,log_level):
        # Criando logger
        logger = log_backup.getLogger(self.sid)
        logger.setLevel(log_level)
        logger.propagate = False
        # Criando console handler e setando o level para o debug
        formato = (dt.datetime.now()).strftime("%Y-%m-%d-%H%M%S.%f")[:-3]
        filename = ('D:\\projeto\\log\\{}_{}_{}.log'.format(self.sid,self.tipo_backup,formato))
        log = log_backup.FileHandler(filename)
        log.setLevel(log_level)
        # Criando Formato
        formatter = log_backup.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s")
        # Adicionando formatter no ch
        log.setFormatter(formatter)
        # Adicionando ch no logger
        logger.addHandler(log) 

#    @staticmethod
    def cria_script_backup (self):
        self.def_backup()
        carregar_arquivo = FileSystemLoader ('D:\\projeto\\templates')    
        ambiente = Environment(loader=carregar_arquivo)
        template = ambiente.get_template('backupsh.j2')    
        Output = template.render(crosscheck=self.crosscheck ,archive=self.archive ,sectionsize=self.sectionsize, backup_level=self.backup_level, DIR_BASE = '', FRA_DEST = '')
        backup = open ('D:\\projeto\\backup\\backup_{}_{}.sh'.format(self.sid,self.tipo_backup),'w') 
        backup.write(Output)
        backup.close()

    #TODO: IMPLEMENTAR O EXECUTA BACKUP
    def executa_backup(self,log_level):
        data_atual = dt.datetime.now()
        
        #Pegando apenas o conteúdo da tupla do ultimo backup full
        for data in self.obtem_data_ultimo_backup_full():
            str_data_ultimo_backup = data[0]
        #Convertendo str em datetime e pegando a diferença em dias 
        dt_data_ultimo_backup = dt.datetime.strptime(str_data_ultimo_backup,"%Y-%m-%d %H:%M:%S")
        difdate = (data_atual - dt_data_ultimo_backup)
        #Convertendo Tipo de backup Full em Incremental caso o tempo seja menor que 12 horas
        if (self.tipo_backup == 'FULL' and difdate.total_seconds()/60/60 > 12):
            self.tipo_backup = 'INCREMENTAL'
        
        self.setup_logger(log_level)
        logger = log_backup.getLogger(self.sid)
       
        time_waiting = 5*random.random()
        logger.info("Instancia {}\tWaiting {} seconds".format(self.sid, time_waiting))

        self.cria_script_backup()

        print("Instancia {}\tWaiting {} seconds".format(self.sid, time_waiting))
        time.sleep(int(time_waiting))