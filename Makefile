PACKAGE=zimbra-core-aspell
DESCRIPTION=Zimbra aspell service

ifeq ($(zimbra_buildinfo_version),)
zimbra.buildinfo.version := 8.8.15
endif

ifeq ($(zimbra.buildinfo.release),)
zimbra.buildinfo.release := 0
endif

STAGEDIR := build/stage/$(PACKAGE)

CONF_FILES := \
    dhparam.pem.zcs zmlogrotate

BIN_FILES := \
    antispam-mysql antispam-mysql.server antispam-mysqladmin \
    ldap.production mysql mysql.server mysqladmin postconf postfix \
    qshape zmaccts zmamavisdctl zmantispamctl zmantispamdbpasswd \
    zmantivirusctl zmapachectl zmarchivectl zmauditswatchctl zmblobchk \
    zmcaldebug zmcbpadmin zmcbpolicydctl zmcertmgr zmclamdctl \
    zmconfigdctl zmcontactbackup zmcontrol zmdedupe zmdhparam \
    zmdnscachectl zmdumpenv zmfixcalendtime zmfixcalprio zmfreshclamctl \
    zmgsautil zmhostname zminnotop zmitemdatafile zmjava zmjavaext \
    zmldappasswd zmldapupgrade zmlmtpinject zmlocalconfig zmloggerctl \
    zmloggerhostmap zmlogswatchctl zmmailbox zmmailboxdctl zmmemcachedctl \
    zmmetadump zmmigrateattrs zmmilterctl zmmtactl zmmypasswd \
    zmmysqlstatus zmmytop zmopendkimctl zmplayredo zmprov zmproxyconf \
    zmproxyctl zmpython zmredodump zmresolverctl zmsaslauthdctl zmshutil \
    zmskindeploy zmsoap zmspellctl zmsshkeygen zmstat-chart \
    zmstat-chart-config zmstatctl zmstorectl zmswatchctl zmthrdump \
    zmtlsctl zmtotp zmtrainsa zmtzupdate zmupdateauthkeys zmvolume \
    zmzimletctl

CONTRIB_FILES := zmfetchercfg

LIBEXEC_FILES := \
    600.zimbra client_usage_report.py configrewrite icalmig \
    libreoffice-installer.sh zcs zimbra zmaltermimeconfig \
    zmantispamdbinit zmantispammycnf zmcbpolicydinit \
    zmcheckduplicatemysqld zmcheckexpiredcerts  zmcleantmp \
    zmclientcertmgr zmcompresslogs zmcomputequotausage zmconfigd \
    zmcpustat zmdailyreport zmdbintegrityreport zmdiaglog \
    zmdkimkeyutil zmdnscachealign zmdomaincertmgr zmexplainslow \
    zmexplainsql zmextractsql zmfixperms zmfixreminder \
    zmgenentitlement zmgsaupdate zmhspreport zminiutil zmiostat \
    zmiptool zmjavawatch zmjsprecompile zmlogger zmloggerinit \
    zmlogprocess zmmsgtrace zmmtainit zmmtastatus zmmycnf \
    zmmyinit zmnotifyinstall zmpostfixpolicyd zmproxyconfgen \
    zmproxyconfig zmproxypurge zmqaction zmqstat zmqueuelog \
    zmrc zmrcd zmresetmysqlpassword zmrrdfetch zmsacompile \
    zmsaupdate zmserverips zmsetservername zmsnmpinit \
    zmspamextract zmstat-allprocs zmstat-cleanup zmstat-convertd \
    zmstat-cpu zmstat-df zmstat-fd zmstat-io zmstat-mtaqueue \
    zmstat-mysql zmstat-nginx zmstat-proc zmstat-vm zmstatuslog \
    zmsyslogsetup zmthreadcpu zmunbound zmupdatedownload zmupdatezco

install-bin:
	mkdir -p $(STAGEDIR)/opt/zimbra/bin/
	for f in $(BIN_FILES); do \
            install -m u=rwx,g=rx -D src/bin/$$f $(STAGEDIR)/opt/zimbra/bin ; \
	done

install-conf:
	mkdir -p $(STAGEDIR)/opt/zimbra/conf/
	for f in $(CONF_FILES); do \
            install -m u=rwx,g=rx -D conf/$$f $(STAGEDIR)/opt/zimbra/conf ; \
	done

install-contrib:
	mkdir -p $(STAGEDIR)/opt/zimbra/contrib/
	for f in $(CONTRIB_FILES); do \
            install -m u=rwx,g=rx -D src/contrib/$$f $(STAGEDIR)/opt/zimbra/contrib ; \
	done

install-libexec:
	mkdir -p $(STAGEDIR)/opt/zimbra/libexec/
	for f in $(LIBEXEC_FILES); do \
            install -m u=rwx,g=rx -D src/libexec/$$f $(STAGEDIR)/opt/zimbra/libexec ; \
	done

install-scripts:
	mkdir -p $(STAGEDIR)/opt/zimbra/libexec/scripts
	install -m u=rwx,g=rx -D src/perl/migrate20131014-removezca.pl $(STAGEDIR)/opt/zimbra/libexec/scripts

install:	install-bin install-conf install-contrib install-libexec install-scripts

pkg:	install
	../zm-pkg-tool/pkg-build.pl \
            --out-type=binary \
            --pkg-name="$(PACKAGE)" \
            --pkg-version="$(zimbra.buildinfo.version)" \
            --pkg-release="$(zimbra.buildinfo.release)" \
            --pkg-summary="$(DESCRIPTION)" \
            --pkg-installs=/opt/zimbra/

clean:
	rm -Rf build

.PHONY: install pkg clean
