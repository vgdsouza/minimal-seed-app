
/**
  @file
  @brief Auto-generated file
  @details
    This file contains all the macros in a single file - which means it can be
    'included' in SAS with just 2 lines of code:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

    The `build.py` file in the https://github.com/sasjs/core repo
    is used to create this file.

  @author Allan Bowe
**/
options noquotelenmax;
/**
  @file
  @brief Abort, ungracefully
  @details Will abort with a straightforward %abort if the condition is true.

  <h4> Related Macros </h4>
  @li mp_abort.sas

  @version 9.2
  @author Allan Bowe
  @cond
**/

%macro mf_abort(mac=mf_abort.sas, type=deprecated, msg=, iftrue=%str(1=1)
)/*/STORE SOURCE*/;

  %if not(%eval(%unquote(&iftrue))) %then %return;

  %put NOTE: ///  mf_abort macro executing //;
  %if %length(&mac)>0 %then %put NOTE- called by &mac;
  %put NOTE - &msg;

  %abort;

%mend mf_abort;

/** @endcond *//**
  @file
  @brief de-duplicates a macro string
  @details Removes all duplicates from a string of words.  A delimeter can be
  chosen.  Is inspired heavily by this excellent [macro](
  https://github.com/scottbass/SAS/blob/master/Macro/dedup_mstring.sas) from
  [Scott Base](https://www.linkedin.com/in/scottbass).  Case sensitive.

  Usage:

      %let str=One two one two and through and through;
      %put %mf_dedup(&str);
      %put %mf_dedup(&str,outdlm=%str(,));

  Which returns:

      > One two one and through
      > One,two,one,and,through

  @param [in] str String to be deduplicated
  @param [in] indlm= ( ) Delimeter of the input string
  @param [out] outdlm= ( ) Delimiter of the output string

  <h4> Related Macros </h4>
  @li mf_trimstr.sas
  @li mf_wordsinstr1butnotstr2.sas

  @version 9.2
  @author Allan Bowe
**/

%macro mf_dedup(str
  ,indlm=%str( )
  ,outdlm=%str( )
)/*/STORE SOURCE*/;

%local num word i pos out;

%* loop over each token, searching the target for that token ;
%let num=%sysfunc(countc(%superq(str),%str(&indlm)));
%do i=1 %to %eval(&num+1);
  %let word=%scan(%superq(str),&i,%str(&indlm));
  %let pos=%sysfunc(indexw(&out,&word,%str(&outdlm)));
  %if (&pos eq 0) %then %do;
    %if (&i gt 1) %then %let out=&out%str(&outdlm);
    %let out=&out&word;
  %end;
%end;

%unquote(&out)

%mend mf_dedup;


/**
  @file mf_existds.sas
  @brief Checks whether a dataset OR a view exists.
  @details Can be used in open code, eg as follows:

      %if %mf_existds(libds=work.someview) %then %put  yes it does!;

  NOTE - some databases have case sensitive tables, for instance POSTGRES
    with the preserve_tab_names=yes libname setting.  This may impact
    expected results (depending on whether you 'expect' the result to be
    case insensitive in this context!)

  @param libds library.dataset
  @return output returns 1 or 0

  <h4> Related Macros </h4>
  @li mf_existds.test.sas

  @warning Untested on tables registered in metadata but not physically present
  @version 9.2
  @author Allan Bowe
**/

%macro mf_existds(libds
)/*/STORE SOURCE*/;

  %if %sysfunc(exist(&libds)) ne 1 & %sysfunc(exist(&libds,VIEW)) ne 1 %then 0;
  %else 1;

%mend mf_existds;
/**
  @file
  @brief Checks whether a feature exists
  @details Check to see if a feature is supported in your environment.
    Run without arguments to see a list of detectable features.
    Note - this list is based on known versions of SAS rather than
    actual feature detection, as that is tricky / impossible to do
    without generating errs in most cases.

        %put %mf_existfeature(PROCLUA);

  @param feature the feature to detect.  Leave blank to list all in log.

  @return output returns 1 or 0 (or -1 if not found)

  <h4> SAS Macros </h4>
  @li mf_getplatform.sas


  @version 8
  @author Allan Bowe
**/
/** @cond */

%macro mf_existfeature(feature
)/*/STORE SOURCE*/;
  %let feature=%upcase(&feature);
  %local platform;
  %let platform=%mf_getplatform();

  %if &feature= %then %do;
    %put Supported features:  PROCLUA;
  %end;
  %else %if &feature=PROCLUA %then %do;
    /* https://blogs.sas.com/content/sasdummy/2015/08/03/using-lua-within-your-sas-programs */
    %if &platform=SASVIYA %then 1;
    %else %if "&sysver"="9.2" or "&sysver"="9.3" %then 0;
    %else %if "&SYSVLONG" < "9.04.01M3" %then 0;
    %else 1;
  %end;
  %else %do;
    -1
    %put &sysmacroname: &feature not found;
  %end;
%mend mf_existfeature;

/** @endcond *//**
  @file
  @brief Checks whether a fileref exists
  @details You can probably do without this macro as it is just a one liner.
  Mainly it is here as a convenient way to remember the syntax!

  @param fref the fileref to detect

  @return output Returns 1 if found and 0 if not found.  Note - it is possible
  that the fileref is found, but the file does not (yet) exist. If you need
  to test for this, you may as well use the fileref function directly.

  @version 8
  @author [Allan Bowe](https://www.linkedin.com/in/allanbowe/)
**/

%macro mf_existfileref(fref
)/*/STORE SOURCE*/;

  %local rc;
  %let rc=%sysfunc(fileref(&fref));
  %if &rc=0 %then %do;
    1
  %end;
  %else %if &rc<0 %then %do;
    %put &sysmacroname: Fileref &fref exists but the underlying file does not;
    1
  %end;
  %else %do;
    0
  %end;

%mend mf_existfileref;/**
  @file
  @brief Checks if a function exists
  @details Returns 1 if the function exists, else 0.  Note that this function
  can be slow as it needs to open the sashelp.vfuncs table.

  Usage:

      %put %mf_existfunction(CAT);
      %put %mf_existfunction(DOG);

  Full credit to [Bart](https://sasensei.com/user/305) for the vfunc pointer
  and the tidy approach for pure macro data set filtering.
  Check out his [SAS Packages](https://github.com/yabwon/SAS_PACKAGES)
  framework!  Where you can find the same [function](
https://github.com/yabwon/SAS_PACKAGES/blob/main/packages/baseplus.md#functionexists-macro
  ).

  @param [in] name (positional) - function name

  @author Allan Bowe
**/
/** @cond */
%macro mf_existfunction(name
)/*/STORE SOURCE*/;

  %local dsid rc exist;
  %let dsid=%sysfunc(open(sashelp.vfunc(where=(fncname="%upcase(&name)"))));
  %let exist=1;
  %let exist=%sysfunc(fetch(&dsid, NOSET));
  %let rc=%sysfunc(close(&dsid));

  %sysevalf(0 = &exist)

%mend mf_existfunction;

/** @endcond *//**
  @file
  @brief Checks if a variable exists in a data set.
  @details Returns 0 if the variable does NOT exist, and return the position of
    the var if it does.
    Usage:

        %put %mf_existvar(work.someds, somevar)

  @param [in] libds 2 part dataset or view reference
  @param [in] var variable name

  <h4> Related Macros </h4>
  @li mf_existvar.test.sas

  @version 9.2
  @author Allan Bowe
**/
/** @cond */

%macro mf_existvar(libds /* 2 part dataset name */
      , var /* variable name */
)/*/STORE SOURCE*/;

  %local dsid rc;
  %let dsid=%sysfunc(open(&libds,is));

  %if &dsid=0 or %length(&var)=0 %then %do;
    %put %sysfunc(sysmsg());
      0
  %end;
  %else %do;
      %sysfunc(varnum(&dsid,&var))
      %let rc=%sysfunc(close(&dsid));
  %end;

%mend mf_existvar;

/** @endcond *//**
  @file
  @brief Checks if a set of variables ALL exist in a data set.
  @details Returns 0 if ANY of the variables do not exist, or 1 if they ALL do.
  Usage:

      %put %mf_existVarList(sashelp.class, age sex name dummyvar);

  <h4> SAS Macros </h4>
  @li mf_abort.sas

  @param libds 2 part dataset or view reference
  @param varlist space separated variable names

  @version 9.2
  @author Allan Bowe
  @cond
**/

%macro mf_existvarlist(libds, varlist
)/*/STORE SOURCE*/;

  %if %str(&libds)=%str() or %str(&varlist)=%str() %then %do;
    %mf_abort(msg=No value provided to libds(&libds) or varlist (&varlist)!
      ,mac=mf_existvarlist.sas)
  %end;

  %local dsid rc i var found;
  %let dsid=%sysfunc(open(&libds,is));

  %if &dsid=0 %then %do;
    %put %str(WARN)ING:  unable to open &libds in mf_existvarlist (&dsid);
  %end;

  %if %sysfunc(attrn(&dsid,NVARS))=0 %then %do;
    %put MF_EXISTVARLIST:  No variables in &libds ;
    0
    %return;
  %end;

  %else %do i=1 %to %sysfunc(countw(&varlist));
    %let var=%scan(&varlist,&i);

    %if %sysfunc(varnum(&dsid,&var))=0  %then %do;
      %let found=&found &var;
    %end;
  %end;

  %let rc=%sysfunc(close(&dsid));
  %if %str(&found)=%str() %then %do;
    1
  %end;
  %else %do;
    0
    %put Vars not found: &found;
  %end;
%mend mf_existvarlist;

/** @endcond *//**
  @file
  @brief Returns the appLoc from the _program variable
  @details When working with SASjs apps, web services / tests / jobs are always
  deployed to a root (app) location in the SAS logical folder tree.

  When building apps for use in other environments, you do not necessarily know
  where the backend services will be deployed.  Therefore a function like this
  is handy in order to dynamically figure out the appLoc, and enable other
  services to be connected by a relative reference.

  SASjs apps always have the same immediate substructure (one or more of the
  following):

  @li /data
  @li /jobs
  @li /services
  @li /tests/jobs
  @li /tests/services
  @li /tests/macros

  This function works by testing for the existence of any of the above in the
  automatic _program variable, and returning the part to the left of it.

  Usage:

      %put %mf_getapploc(&_program)

      %put %mf_getapploc(/some/location/services/admin/myservice);
      %put %mf_getapploc(/some/location/jobs/extract/somejob/);
      %put %mf_getapploc(/some/location/tests/jobs/somejob/);


  @author Allan Bowe
**/

%macro mf_getapploc(pgm);
%if "&pgm"="" %then %do;
  %if %symexist(_program) %then %let pgm=&_program;
  %else %do;
    %put &sysmacroname: No value provided and no _program variable available;
    %return;
  %end;
%end;
%local root;

/**
  * First check we are not in the tests/macros folder (which has no subfolders)
  */
%if %index(&pgm,/tests/macros/) %then %do;
  %let root=%substr(&pgm,1,%index(&pgm,/tests/macros)-1);
  &root
  %return;
%end;

/**
  * Next, move up two levels to avoid matches on subfolder or service name
  */
%let root=%substr(&pgm,1,%length(&pgm)-%length(%scan(&pgm,-1,/))-1);
%let root=%substr(&root,1,%length(&root)-%length(%scan(&root,-1,/))-1);

%if %index(&root,/tests/) %then %do;
  %let root=%substr(&root,1,%index(&root,/tests/)-1);
%end;
%else %if %index(&root,/services) %then %do;
  %let root=%substr(&root,1,%index(&root,/services)-1);
%end;
%else %if %index(&root,/jobs) %then %do;
  %let root=%substr(&root,1,%index(&root,/jobs)-1);
%end;
%else %put &sysmacroname: Could not find an app location from &pgm;
  &root
%mend mf_getapploc ;/**
  @file
  @brief Returns a character attribute of a dataset.
  @details Can be used in open code, eg as follows:

      %put Dataset label = %mf_getattrc(sashelp.class,LABEL);
      %put Member Type = %mf_getattrc(sashelp.class,MTYPE);

  @param libds library.dataset
  @param attr full list in [documentation](
    https://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000147794.htm)
  @return output returns result of the attrc value supplied, or -1 and log
    message if err.

  @version 9.2
  @author Allan Bowe
**/

%macro mf_getattrc(
    libds
    ,attr
)/*/STORE SOURCE*/;
  %local dsid rc;
  %let dsid=%sysfunc(open(&libds,is));
  %if &dsid = 0 %then %do;
    %put %str(WARN)ING: Cannot open %trim(&libds), system message below;
    %put %sysfunc(sysmsg());
    -1
  %end;
  %else %do;
    %sysfunc(attrc(&dsid,&attr))
    %let rc=%sysfunc(close(&dsid));
  %end;
%mend mf_getattrc;/**
  @file
  @brief Returns a numeric attribute of a dataset.
  @details Can be used in open code, eg as follows:

      %put Number of observations=%mf_getattrn(sashelp.class,NLOBS);
      %put Number of variables = %mf_getattrn(sashelp.class,NVARS);

  @param libds library.dataset
  @param attr Common values are NLOBS and NVARS, full list in [documentation](
  http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000212040.htm)
  @return output returns result of the attrn value supplied, or -1 and log
    message if err.

  @version 9.2
  @author Allan Bowe
**/

%macro mf_getattrn(
    libds
    ,attr
)/*/STORE SOURCE*/;
  %local dsid rc;
  %let dsid=%sysfunc(open(&libds,is));
  %if &dsid = 0 %then %do;
    %put %str(WARN)ING: Cannot open %trim(&libds), system message below;
    %put %sysfunc(sysmsg());
    -1
  %end;
  %else %do;
    %sysfunc(attrn(&dsid,&attr))
    %let rc=%sysfunc(close(&dsid));
  %end;
%mend mf_getattrn;/**
  @file
  @brief Returns the engine type of a SAS library
  @details Usage:

      %put %mf_getengine(SASHELP);

  returns:
  > V9

  A note is also written to the log.  The credit for this macro goes to the
  contributors of Chris Hemedingers blog [post](
  http://blogs.sas.com/content/sasdummy/2013/06/04/find-a-sas-library-engine/)

  @param [in] libref Library reference (also accepts a 2 level libds ref).

  @return output returns the library engine (uppercase) for the FIRST library
    encountered.

  @warning will only return the FIRST library engine - for concatenated
    libraries, with different engines, inconsistent results may be encountered.

  @version 9.2
  @author Allan Bowe

  <h4> Related Macros </h4>
  @li mf_getxengine.sas

**/
/** @cond */

%macro mf_getengine(libref
)/*/STORE SOURCE*/;
  %local dsid engnum rc engine;

  /* in case the parameter is a libref.tablename, pull off just the libref */
  %let libref = %upcase(%scan(&libref, 1, %str(.)));

  %let dsid=%sysfunc(
    open(sashelp.vlibnam(where=(libname="%upcase(&libref)")),i)
  );
  %if (&dsid ^= 0) %then %do;
    %let engnum=%sysfunc(varnum(&dsid,ENGINE));
    %let rc=%sysfunc(fetch(&dsid));
    %let engine=%sysfunc(getvarc(&dsid,&engnum));
    %put &libref. ENGINE is &engine.;
    %let rc= %sysfunc(close(&dsid));
  %end;

  %upcase(&engine)

%mend mf_getengine;

/** @endcond *//**
  @file
  @brief Returns the size of a file in bytes.
  @details Provide full path/filename.extension to the file, eg:

      %put %mf_getfilesize(fpath=C:\temp\myfile.txt);

      or

      data x;do x=1 to 100000;y=x;output;end;run;
      %put %mf_getfilesize(libds=work.x,format=yes);

      gives:

      2mb

  @param fpath= full path and filename.  Provide this OR the libds value.
  @param libds= library.dataset value (assumes library is BASE engine)
  @param format=  set to yes to apply sizekmg. format
  @returns bytes

  @version 9.2
  @author Allan Bowe
**/

%macro mf_getfilesize(fpath=,libds=0,format=NO
)/*/STORE SOURCE*/;

  %if &libds ne 0 %then %do;
    %let fpath=%sysfunc(pathname(%scan(&libds,1,.)))/%scan(&libds,2,.).sas7bdat;
  %end;

  %local rc fid fref bytes;
  %let rc=%sysfunc(filename(fref,&fpath));
  %let fid=%sysfunc(fopen(&fref));
  %let bytes=%sysfunc(finfo(&fid,File Size (bytes)));
  %let rc=%sysfunc(fclose(&fid));
  %let rc=%sysfunc(filename(fref));

  %if &format=NO %then %do;
    &bytes
  %end;
  %else %do;
    %sysfunc(INPUTN(&bytes, best.),sizekmg.)
  %end;

%mend mf_getfilesize ;/**
  @file
  @brief Returns a distinct list of formats from a table
  @details Reads the dataset header and returns a distinct list of formats
  applied.

        %put NOTE- %mf_getfmtlist(sashelp.prdsale);
        %put NOTE- %mf_getfmtlist(sashelp.shoes);
        %put NOTE- %mf_getfmtlist(sashelp.demographics);

  returns:

  > DOLLAR $CHAR W MONNAME
  > $CHAR BEST DOLLAR
  > BEST Z $CHAR COMMA PERCENTN


  @param [in] libds Two part library.dataset reference.

  <h4> SAS Macros </h4>
  @li mf_getfmtname.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mf_getfmtlist(libds
)/*/STORE SOURCE*/;
/* declare local vars */
%local out dsid nvars x rc fmt;

/* open dataset in macro */
%let dsid=%sysfunc(open(&libds));

/* continue if dataset exists */
%if &dsid %then %do;
  /* loop each variable in the dataset */
  %let nvars=%sysfunc(attrn(&dsid,NVARS));
  %do x=1 %to &nvars;
    /* grab format and check it exists */
    %let fmt=%sysfunc(varfmt(&dsid,&x));
    %if %quote(&fmt) ne %quote() %then %let fmt=%mf_getfmtname(&fmt);
    %else %do;
      /* assign default format depending on variable type */
      %if %sysfunc(vartype(&dsid, &x))=C %then %let fmt=$CHAR;
      %else %let fmt=BEST;
    %end;
    /* concatenate unique list of formats */
    %if %sysfunc(indexw(&out,&fmt,%str( )))=0 %then %let out=&out &fmt;
  %end;
  %let rc=%sysfunc(close(&dsid));
%end;
%else %do;
  %put &sysmacroname: Unable to open &libds (rc=&dsid);
  %put &sysmacroname: SYSMSG= %sysfunc(sysmsg());
  %let rc=%sysfunc(close(&dsid));
%end;
/* send them out without spaces or quote markers */
%do;%unquote(&out)%end;
%mend mf_getfmtlist;/**
  @file
  @brief Extracts a format name from a fully defined format
  @details Converts formats in like $thi3. and th13.2 $THI and TH.
  Usage:

      %put %mf_getfmtname(8.);
      %put %mf_getfmtname($4.);
      %put %mf_getfmtname(comma14.10);

  Returns:

  > W
  > $CHAR
  > COMMA

  Note that system defaults are inferred from the values provided.

  @param [in] fmt The fully defined format. If left blank, nothing is returned.

  @returns The name (without width or decimal) of the format.

  @version 9.2
  @author Allan Bowe

**/

%macro mf_getfmtname(fmt
)/*/STORE SOURCE*/ /minoperator mindelimiter=' ';

%local out dsid nvars x rc fmt;

/* extract actual format name from the format definition */
%let fmt=%scan(&fmt,1,.);
%do %while(%substr(&fmt,%length(&fmt),1) in 1 2 3 4 5 6 7 8 9 0);
  %if %length(&fmt)=1 %then %let fmt=W;
  %else %let fmt=%substr(&fmt,1,%length(&fmt)-1);
%end;

%if &fmt=$ %then %let fmt=$CHAR;

/* send them out without spaces or quote markers */
%do;%unquote(%upcase(&fmt))%end;
%mend mf_getfmtname;/**
  @file
  @brief retrieves a key value pair from a control dataset
  @details By default, control dataset is work.mp_setkeyvalue.  Usage:

      %mp_setkeyvalue(someindex,22,type=N)
      %put %mf_getkeyvalue(someindex)


  @param key Provide a key on which to perform the lookup
  @param libds= define the target table which holds the parameters

  @version 9.2
  @author Allan Bowe
**/

%macro mf_getkeyvalue(key,libds=work.mp_setkeyvalue
)/*/STORE SOURCE*/;
%local ds dsid key valc valn type rc;
%let dsid=%sysfunc(open(&libds(where=(key="&key"))));
%syscall set(dsid);
%let rc = %sysfunc(fetch(&dsid));
%let rc = %sysfunc(close(&dsid));

%if &type=N %then %do;
  &valn
%end;
%else %if &type=C %then %do;
  &valc
%end;
%else %put %str(ERR)OR: Unable to find key &key in ds &libds;
%mend mf_getkeyvalue;/**
  @file mf_getplatform.sas
  @brief Returns platform specific variables
  @details Enables platform specific variables to be returned

      %put %mf_getplatform();

    returns:
      SASMETA  (or SASVIYA)

  @param switch the param for which to return a platform specific variable

  <h4> SAS Macros </h4>
  @li mf_mval.sas
  @li mf_trimstr.sas

  @version 9.4 / 3.4
  @author Allan Bowe
**/

%macro mf_getplatform(switch
)/*/STORE SOURCE*/;
%local a b c;
%if &switch.NONE=NONE %then %do;
  %if %symexist(sysprocessmode) %then %do;
    %if "&sysprocessmode"="SAS Object Server"
    or "&sysprocessmode"= "SAS Compute Server" %then %do;
        SASVIYA
    %end;
    %else %if "&sysprocessmode"="SAS Stored Process Server"
      or "&sysprocessmode"="SAS Workspace Server"
    %then %do;
      SASMETA
      %return;
    %end;
    %else %do;
      BASESAS
      %return;
    %end;
  %end;
  %else %if %symexist(_metaport) or %symexist(_metauser) %then %do;
    SASMETA
    %return;
  %end;
  %else %do;
    BASESAS
    %return;
  %end;
%end;
%else %if &switch=SASSTUDIO %then %do;
  /* return the version of SAS Studio else 0 */
  %if %mf_mval(_CLIENTAPP)=%str(SAS Studio) %then %do;
    %let a=%mf_mval(_CLIENTVERSION);
    %let b=%scan(&a,1,.);
    %if %eval(&b >2) %then %do;
      &b
    %end;
    %else 0;
  %end;
  %else 0;
%end;
%else %if &switch=VIYARESTAPI %then %do;
  %mf_trimstr(%sysfunc(getoption(servicesbaseurl)),/)
%end;
%mend mf_getplatform;/**
  @file
  @brief Adds custom quotes / delimiters to a  delimited string
  @details Can be used in open code, eg as follows:

      %put %mf_getquotedstr(blah   blah  blah);

  which returns:
> 'blah','blah','blah'

  Alternatively:

      %put %mf_getquotedstr(these words are double quoted,quote=D)

  for:
> "these","words","are","double","quoted"

  @param [in] in_str The unquoted, spaced delimited string to transform
  @param [in] dlm= (,) The delimeter to be applied to the output (default comma)
  @param [in] indlm= ( ) The delimeter used for the input (default is space)
  @param [in] quote= (S) The quote mark to apply (S=Single, D=Double, N=None).
    If any other value than uppercase S or D is supplied, then that value will
    be used as the quoting character.
  @return output returns a string with the newly quoted / delimited output.

  @version 9.2
  @author Allan Bowe
**/


%macro mf_getquotedstr(IN_STR
  ,DLM=%str(,)
  ,QUOTE=S
  ,indlm=%str( )
)/*/STORE SOURCE*/;
  /* credit Rowland Hale  - byte34 is double quote, 39 is single quote */
  %if &quote=S %then %let quote=%qsysfunc(byte(39));
  %else %if &quote=D %then %let quote=%qsysfunc(byte(34));
  %else %if &quote=N %then %let quote=;
  %local i item buffer;
  %let i=1;
  %do %while (%qscan(&IN_STR,&i,%str(&indlm)) ne %str() ) ;
    %let item=%qscan(&IN_STR,&i,%str(&indlm));
    %if %bquote(&QUOTE) ne %then %let item=&QUOTE%qtrim(&item)&QUOTE;
    %else %let item=%qtrim(&item);

    %if (&i = 1) %then %let buffer =%qtrim(&item);
    %else %let buffer =&buffer&DLM%qtrim(&item);

    %let i = %eval(&i+1);
  %end;

  %let buffer=%sysfunc(coalescec(%qtrim(&buffer),&QUOTE&QUOTE));

  &buffer

%mend mf_getquotedstr;/**
  @file mf_getschema.sas
  @brief Returns the database schema of a SAS library
  @details Usage:

      %put %mf_getschema(MYDB);

  returns:
  > dbo

  @param libref Library reference (also accepts a 2 level libds ref).

  @return output returns the library schema for the FIRST library encountered

  @warning will only return the FIRST library schema - for concatenated
    libraries, with different schemas, inconsistent results may be encountered.

  @version 9.2
  @author Allan Bowe
  @cond
**/

%macro mf_getschema(libref
)/*/STORE SOURCE*/;
  %local dsid vnum rc schema;
  /* in case the parameter is a libref.tablename, pull off just the libref */
  %let libref = %upcase(%scan(&libref, 1, %str(.)));
  %let dsid=%sysfunc(open(sashelp.vlibnam(where=(
    libname="%upcase(&libref)" and sysname='Schema/Owner'
  )),i));
  %if (&dsid ^= 0) %then %do;
    %let vnum=%sysfunc(varnum(&dsid,SYSVALUE));
    %let rc=%sysfunc(fetch(&dsid));
    %let schema=%sysfunc(getvarc(&dsid,&vnum));
    %put &libref. schema is &schema.;
    %let rc= %sysfunc(close(&dsid));
  %end;

  &schema

%mend mf_getschema;

/** @endcond */
/**
  @file
  @brief Assigns and returns an unused fileref
  @details  Using the native approach for assigning filerefs fails as some
  procedures (such as proc http) do not recognise the temporary names (starting
  with a hash), returning a message such as:

  > ERROR 22-322: Expecting a name.

  This macro works by attempting a random fileref (with a prefix), seeing if it
  is already assigned, and if not - returning the fileref.

  If your process can accept filerefs with the hash (#) prefix, then set
  `prefix=0` to revert to the native approach - which is significantly faster
  when there are a lot of filerefs in a session.

  Use as follows:

      %let fileref1=%mf_getuniquefileref();
      %let fileref2=%mf_getuniquefileref(prefix=0);
      %put &fileref1 &fileref2;

  which returns filerefs similar to:

> _7432233 #LN00070

  @param [in] prefix= (_) first part of fileref. Remember that filerefs can only
    be 8 characters, so a 7 letter prefix would mean `maxtries` should be 10.
    if using zero (0) as the prefix, a native assignment is used.
  @param [in] maxtries= (1000) the last part of the libref. Must be an integer.

  @version 9.2
  @author Allan Bowe
**/

%macro mf_getuniquefileref(prefix=_,maxtries=1000);
  %local rc fname;
  %if &prefix=0 %then %do;
    %let rc=%sysfunc(filename(fname,,temp));
    %if &rc %then %put %sysfunc(sysmsg());
    &fname
  %end;
  %else %do;
    %local x len;
    %let len=%eval(8-%length(&prefix));
    %let x=0;
    %do x=0 %to &maxtries;
      %let fname=&prefix%substr(%sysfunc(ranuni(0)),3,&len);
      %if %sysfunc(fileref(&fname)) > 0 %then %do;
        %let rc=%sysfunc(filename(fname,,temp));
        %if &rc %then %put %sysfunc(sysmsg());
        &fname
        %return;
      %end;
    %end;
    %put unable to find available fileref after &maxtries attempts;
  %end;
%mend mf_getuniquefileref;/**
  @file
  @brief Returns an unused libref
  @details Use as follows:

    libname mclib0 (work);
    libname mclib1 (work);
    libname mclib2 (work);

    %let libref=%mf_getuniquelibref();
    %put &=libref;

  which returns:

> mclib3

  @param prefix= first part of libref.  Remember that librefs can only be 8 characters,
    so a 7 letter prefix would mean that maxtries should be 10.
  @param maxtries= the last part of the libref.  Provide an integer value.

  @version 9.2
  @author Allan Bowe
**/


%macro mf_getuniquelibref(prefix=mclib,maxtries=1000);
  %local x libref;
  %let x=0;
  %do x=0 %to &maxtries;
  %if %sysfunc(libref(&prefix&x)) ne 0 %then %do;
    %let libref=&prefix&x;
    %let rc=%sysfunc(libname(&libref,%sysfunc(pathname(work))));
    %if &rc %then %put %sysfunc(sysmsg());
    &prefix&x
    %*put &sysmacroname: Libref &libref assigned as WORK and returned;
    %return;
  %end;
  %end;
  %put unable to find available libref in range &prefix.0-&maxtries;
%mend mf_getuniquelibref;/**
  @file mf_getuniquename.sas
  @brief Returns a shortened (32 char) GUID as a valid SAS name
  @details Use as follows:

      %let myds=%mf_getuniquename();
      %put &=myds;

  which returns:

> MCc59c750610321d4c8bf75faadbcd22

  @param prefix= set a prefix for the new name

  @version 9.3
  @author Allan Bowe
**/


%macro mf_getuniquename(prefix=MC);
&prefix.%substr(%sysfunc(compress(%sysfunc(uuidgen()),-)),1,32-%length(&prefix))
%mend mf_getuniquename;/**
  @file
  @brief Returns a userid according to session context
  @details In a workspace session, a user is generally represented by <code>
    &sysuserid</code> or <code>SYS_COMPUTE_SESSION_OWNER</code> if it exists.
    In a Stored Process session, <code>&sysuserid</code>
    resolves to a system account (default=sassrv) and instead there are several
    metadata username variables to choose from (_metauser, _metaperson
    ,_username, _secureusername).  The OS account is represented by
    <code> _secureusername</code> whilst the metadata account is under <code>
    _metaperson</code>.

        %let user= %mf_getUser();
        %put &user;

  @param type - do not use, may be deprecated in a future release

  @return SYSUSERID (if workspace server)
  @return _METAPERSON (if stored process server)
  @return SYS_COMPUTE_SESSION_OWNER (if Viya compute session)

  @version 9.2
  @author Allan Bowe
**/

%macro mf_getuser(type=META
)/*/STORE SOURCE*/;
  %local user metavar;
  %if &type=OS %then %let metavar=_secureusername;
  %else %let metavar=_metaperson;

  %if %symexist(SYS_COMPUTE_SESSION_OWNER) %then %let user=&SYS_COMPUTE_SESSION_OWNER;
  %else %if %symexist(&metavar) %then %do;
    %if %length(&&&metavar)=0 %then %let user=&sysuserid;
    /* sometimes SAS will add @domain extension - remove for consistency */
    %else %let user=%scan(&&&metavar,1,@);
  %end;
  %else %let user=&sysuserid;

  %quote(&user)

%mend mf_getuser;
/**
  @file
  @brief Retrieves a value from a dataset.  If no filter supplied, then first
    record is used.
  @details Be sure to <code>%quote()</code> your where clause.  Example usage:

      %put %mf_getvalue(sashelp.class,name,filter=%quote(age=15));
      %put %mf_getvalue(sashelp.class,name);

  <h4> SAS Macros </h4>
  @li mf_getattrn.sas

  <h4> Related Macros </h4>
  @li mp_setkeyvalue.sas

  @param libds dataset to query
  @param variable the variable which contains the value to return.
  @param filter contents of where clause

  @version 9.2
  @author Allan Bowe
**/

%macro mf_getvalue(libds,variable,filter=1
)/*/STORE SOURCE*/;
  %if %mf_getattrn(&libds,NLOBS)>0 %then %do;
    %local dsid rc &variable;
    %let dsid=%sysfunc(open(&libds(where=(&filter))));
    %syscall set(dsid);
    %let rc = %sysfunc(fetch(&dsid));
    %let rc = %sysfunc(close(&dsid));

    %trim(&&&variable)

  %end;
%mend mf_getvalue;/**
  @file
  @brief Returns number of variables in a dataset
  @details Useful to identify those renagade datasets that have no columns!

        %put Number of Variables=%mf_getvarcount(sashelp.class);

  returns:
  > Number of Variables=4

  @param libds Two part dataset (or view) reference.

  @version 9.2
  @author Allan Bowe

**/

%macro mf_getvarcount(libds
)/*/STORE SOURCE*/;
  %local dsid nvars rc ;
  %let dsid=%sysfunc(open(&libds));
  %let nvars=.;
  %if &dsid %then %do;
    %let nvars=%sysfunc(attrn(&dsid,NVARS));
    %let rc=%sysfunc(close(&dsid));
  %end;
  %else %do;
    %put unable to open &libds (rc=&dsid);
    %let rc=%sysfunc(close(&dsid));
  %end;
  &nvars
%mend mf_getvarcount;/**
  @file
  @brief Returns the format of a variable
  @details Uses varfmt function to identify the format of a particular variable.
  Usage:

      data test;
        format str1 $1.  num1 datetime19.;
        str2='hello mum!'; num2=666;
        stop;
      run;
      %put %mf_getVarFormat(test,str1);
      %put %mf_getVarFormat(work.test,num1);
      %put %mf_getVarFormat(test,str2,force=1);
      %put %mf_getVarFormat(work.test,num2,force=1);
      %put %mf_getVarFormat(test,renegade);

  returns:

      $1.
      DATETIME19.
      $10.
      8.
      NOTE: Variable renegade does not exist in test

  @param [in] libds Two part dataset (or view) reference.
  @param [in] var Variable name for which a format should be returned
  @param [in] force=(0) Set to 1 to supply a default if the variable has no format
  @returns outputs format

  @author Allan Bowe
  @version 9.2
**/

%macro mf_getVarFormat(libds /* two level ds name */
      , var /* variable name from which to return the format */
      , force=0
)/*/STORE SOURCE*/;
  %local dsid vnum vformat rc vlen vtype;
  /* Open dataset */
  %let dsid = %sysfunc(open(&libds));
  %if &dsid > 0 %then %do;
    /* Get variable number */
    %let vnum = %sysfunc(varnum(&dsid, &var));
    /* Get variable format */
    %if(&vnum > 0) %then %let vformat=%sysfunc(varfmt(&dsid, &vnum));
    %else %do;
      %put NOTE: Variable &var does not exist in &libds;
      %let rc = %sysfunc(close(&dsid));
      %return;
    %end;
  %end;
  %else %do;
    %put &sysmacroname: dataset &libds not opened! (rc=&dsid);
    %put &sysmacroname: %sysfunc(sysmsg());
    %return;
  %end;

  /* supply a default if no format available */
  %if %length(&vformat)<2 & &force=1 %then %do;
    %let vlen = %sysfunc(varlen(&dsid, &vnum));
    %let vtype = %sysfunc(vartype(&dsid, &vnum.));
    %if &vtype=C %then %let vformat=$&vlen..;
    %else %let vformat=best.;
  %end;


  /* Close dataset */
  %let rc = %sysfunc(close(&dsid));
  /* Return variable format */
  &vformat
%mend mf_getVarFormat;/**
  @file
  @brief Returns the length of a variable
  @details Uses varlen function to identify the length of a particular variable.
  Usage:

      data test;
        format str $1.  num datetime19.;
        stop;
      run;
      %put %mf_getVarLen(test,str);
      %put %mf_getVarLen(work.test,num);
      %put %mf_getVarLen(test,renegade);

  returns:

      1
      8
      NOTE: Variable renegade does not exist in test

  @param libds Two part dataset (or view) reference.
  @param var Variable name for which a length should be returned
  @returns outputs length

  @author Allan Bowe
  @version 9.2

**/

%macro mf_getVarLen(libds /* two level ds name */
      , var /* variable name from which to return the length */
)/*/STORE SOURCE*/;
  %local dsid vnum vlen rc;
  /* Open dataset */
  %let dsid = %sysfunc(open(&libds));
  %if &dsid > 0 %then %do;
    /* Get variable number */
    %let vnum = %sysfunc(varnum(&dsid, &var));
    /* Get variable format */
    %if(&vnum > 0) %then %let vlen = %sysfunc(varlen(&dsid, &vnum));
    %else %do;
      %put NOTE: Variable &var does not exist in &libds;
      %let vlen = %str( );
    %end;
  %end;
  %else %do;
    %put &sysmacroname: dataset &libds not opened! (rc=&dsid);
    %put &sysmacroname: %sysfunc(sysmsg());
    %return;
  %end;

  /* Close dataset */
  %let rc = %sysfunc(close(&dsid));
  /* Return variable format */
  &vlen
%mend mf_getVarLen;/**
  @file
  @brief Returns dataset variable list direct from header
  @details WAY faster than dictionary tables or sas views, and can
    also be called in macro logic (is pure macro). Can be used in open code,
    eg as follows:

        %put List of Variables=%mf_getvarlist(sashelp.class);

  returns:
  > List of Variables=Name Sex Age Height Weight

  For a seperated list of column values:

        %put %mf_getvarlist(sashelp.class,dlm=%str(,),quote=double);

  returns:
  > "Name","Sex","Age","Height","Weight"

  @param [in] libds Two part dataset (or view) reference.
  @param [in] dlm= ( ) Provide a delimiter (eg comma or space) to separate the
    variables
  @param [in] quote= (none) use either DOUBLE or SINGLE to quote the results
  @param [in] typefilter= (A) Filter for certain types of column.  Valid values:
    @li A Return All columns
    @li C Return Character columns
    @li N Return Numeric columns

  @version 9.2
  @author Allan Bowe

**/

%macro mf_getvarlist(libds
      ,dlm=%str( )
      ,quote=no
      ,typefilter=A
)/*/STORE SOURCE*/;
  /* declare local vars */
  %local outvar dsid nvars x rc dlm q var vtype;

  /* credit Rowland Hale  - byte34 is double quote, 39 is single quote */
  %if %upcase(&quote)=DOUBLE %then %let q=%qsysfunc(byte(34));
  %else %if %upcase(&quote)=SINGLE %then %let q=%qsysfunc(byte(39));
  /* open dataset in macro */
  %let dsid=%sysfunc(open(&libds));

  %if &dsid %then %do;
    %let nvars=%sysfunc(attrn(&dsid,NVARS));
    %if &nvars>0 %then %do;
      /* add variables with supplied delimeter */
      %do x=1 %to &nvars;
        /* get variable type */
        %let vtype=%sysfunc(vartype(&dsid,&x));
        %if &vtype=&typefilter or &typefilter=A %then %do;
          %let var=&q.%sysfunc(varname(&dsid,&x))&q.;
          %if &var=&q&q %then %do;
            %put &sysmacroname: Empty column found in &libds!;
            %let var=&q. &q.;
          %end;
          %if %quote(&outvar)=%quote() %then %let outvar=&var;
          %else %let outvar=&outvar.&dlm.&var.;
        %end;
      %end;
    %end;
    %let rc=%sysfunc(close(&dsid));
  %end;
  %else %do;
    %put &sysmacroname: Unable to open &libds (rc=&dsid);
    %put &sysmacroname: SYSMSG= %sysfunc(sysmsg());
    %let rc=%sysfunc(close(&dsid));
  %end;
  %do;%unquote(&outvar)%end;
%mend mf_getvarlist;/**
  @file
  @brief Returns the position of a variable in dataset (varnum attribute).
  @details Uses varnum function to determine position.

Usage:

    data work.test;
      format str $1.  num datetime19.;
      stop;
    run;
    %put %mf_getVarNum(work.test,str);
    %put %mf_getVarNum(work.test,num);
    %put %mf_getVarNum(work.test,renegade);

returns:

  > 1

  > 2

  > NOTE: Variable renegade does not exist in test

  @param libds Two part dataset (or view) reference.
  @param var Variable name for which a position should be returned

  @author Allan Bowe
  @version 9.2

**/

%macro mf_getVarNum(libds /* two level ds name */
      , var /* variable name from which to return the format */
)/*/STORE SOURCE*/;
  %local dsid vnum rc;
  /* Open dataset */
  %let dsid = %sysfunc(open(&libds));
  %if &dsid > 0 %then %do;
    /* Get variable number */
    %let vnum = %sysfunc(varnum(&dsid, &var));
    %if(&vnum <= 0) %then %do;
      %put NOTE: Variable &var does not exist in &libds;
      %let vnum = %str( );
    %end;
  %end;
  %else %do;
    %put &sysmacroname: dataset &libds not opened! (rc=&dsid);
    %put &sysmacroname: %sysfunc(sysmsg());
    %return;
  %end;

  /* Close dataset */
  %let rc = %sysfunc(close(&dsid));

  /* Return variable number */
    &vnum.

%mend mf_getVarNum;/**
  @file
  @brief Returns variable type - Character (C) or Numeric (N)
  @details
Usage:

      data test;
        length str $1.  num 8.;
        stop;
      run;
      %put %mf_getvartype(test,str);
      %put %mf_getvartype(work.test,num);



  @param libds Two part dataset (or view) reference.
  @param var the variable name to be checked
  @return output returns C or N depending on variable type.  If variable
    does not exist then a blank is returned and a note is written to the log.

  @version 9.2
  @author Allan Bowe

**/

%macro mf_getvartype(libds /* two level name */
      , var /* variable name from which to return the type */
)/*/STORE SOURCE*/;
  %local dsid vnum vtype rc;
  /* Open dataset */
  %let dsid = %sysfunc(open(&libds));
  %if &dsid. > 0 %then %do;
    /* Get variable number */
    %let vnum = %sysfunc(varnum(&dsid, &var));
    /* Get variable type (C/N) */
    %if(&vnum. > 0) %then %let vtype = %sysfunc(vartype(&dsid, &vnum.));
    %else %do;
      %put NOTE: Variable &var does not exist in &libds;
      %let vtype = %str( );
    %end;
  %end;
  %else %do;
    %put &sysmacroname: dataset &libds not opened! (rc=&dsid);
    %put &sysmacroname: %sysfunc(sysmsg());
    %return;
  %end;

  /* Close dataset */
  %let rc = %sysfunc(close(&dsid));
  /* Return variable type */
  &vtype
%mend mf_getvartype;/**
  @file
  @brief Returns the engine type of a SAS fileref
  @details Queries sashelp.vextfl to get the xengine value.
  Usage:

      filename feng temp;
      %put %mf_getxengine(feng);

  returns:
  > TEMP

  @param fref The fileref to check

  @returns The XENGINE value in sashelp.vextfl or 0 if not found.

  @version 9.2
  @author Allan Bowe

  <h4> Related Macros </h4>
  @li mf_getengine.sas

**/

%macro mf_getxengine(fref
)/*/STORE SOURCE*/;
  %local dsid engnum rc engine;

  %let dsid=%sysfunc(
    open(sashelp.vextfl(where=(fileref="%upcase(&fref)")),i)
  );
  %if (&dsid ^= 0) %then %do;
    %let engnum=%sysfunc(varnum(&dsid,XENGINE));
    %let rc=%sysfunc(fetch(&dsid));
    %let engine=%sysfunc(getvarc(&dsid,&engnum));
    %* put &fref. ENGINE is &engine.;
    %let rc= %sysfunc(close(&dsid));
  %end;
  %else %let engine=0;

  &engine

%mend mf_getxengine;
/**
  @file mf_isblank.sas
  @brief Checks whether a macro variable is empty (blank)
  @details Simply performs:

      %sysevalf(%superq(param)=,boolean)

  Usage:

      %put mf_isblank(&var);

  inspiration:
  https://support.sas.com/resources/papers/proceedings09/022-2009.pdf

  @param param VALUE to be checked

  @return output returns 1 (if blank) else 0

  @version 9.2
**/

%macro mf_isblank(param
)/*/STORE SOURCE*/;

  %sysevalf(%superq(param)=,boolean)

%mend mf_isblank;/**
  @file
  @brief Checks whether a path is a valid directory
  @details
  Usage:

      %let isdir=%mf_isdir(/tmp);

  With thanks and full credit to Andrea Defronzo -
  https://www.linkedin.com/in/andrea-defronzo-b1a47460/

  @param path full path of the file/directory to be checked

  @return output returns 1 if path is a directory, 0 if it is not

  @version 9.2
**/

%macro mf_isdir(path
)/*/STORE SOURCE*/;
  %local rc did is_directory fref_t;

  %let is_directory = 0;
  %let rc = %sysfunc(filename(fref_t, %superq(path)));
  %let did = %sysfunc(dopen(&fref_t.));
  %if &did. ^= 0 %then %do;
    %let is_directory = 1;
    %let rc = %sysfunc(dclose(&did.));
  %end;
  %let rc = %sysfunc(filename(fref_t));

  &is_directory

%mend mf_isdir;/**
  @file
  @brief Returns 1 if the variable contains only digits 0-9, else 0
  @details Note that numerics containing any punctuation (including decimals
    or exponents) will be flagged zero.

  If you'd like support for this, then do raise an issue (or even better, a
  pull request!)

  Usage:

      %put %mf_isint(1) returns 1;
      %put %mf_isint(1.1) returns 0;
      %put %mf_isint(%str(1,1)) returns 0;

  @param [in] arg input value to check

  @version 9.2
**/

%macro mf_isint(arg
)/*/STORE SOURCE*/;
  /* remove minus sign if exists */

  %local val;
  %if "%substr(%str(&arg),1,1)"="-" %then %let val=%substr(%str(&arg),2);
  %else %let val=&arg;

  /* check remaining chars */
  %if %sysfunc(findc(%str(&val),,kd)) %then %do;0%end;
  %else %do;1%end;

%mend mf_isint;/**
  @file
  @brief Checks whether a string follows correct library.dataset format
  @details Many macros in the core library accept a library.dataset parameter
  referred to as 'libds'.  This macro validates the structure of that parameter,
  eg:

    @li 8 character libref?
    @li 32 character dataset?
    @li contains a period?

  It does NOT check whether the dataset exists, or if the library is assigned.

  Usage:

      %put %mf_islibds(work.something)=1;
      %put %mf_islibds(nolib)=0;
      %put %mf_islibds(badlibref.ds)=0;
      %put %mf_islibds(w.t.f)=0;

  @param [in] libds The string to be checked

  @return output Returns 1 if libds is valid, 0 if it is not

  <h4> Related Macros </h4>
  @li mf_islibds.test.sas
  @li mp_validatecol.sas

  @version 9.2
**/

%macro mf_islibds(libds
)/*/STORE SOURCE*/;

%local regex;
%let regex=%sysfunc(prxparse(%str(/^[_a-z]\w{0,7}\.[_a-z]\w{0,31}$/i)));

%sysfunc(prxmatch(&regex,&libds))

%mend mf_islibds;/**
  @file
  @brief Returns physical location of various SAS items
  @details Returns location of the PlatformObjectFramework tools
    Usage:

      %put %mf_loc(POF); %*location of PlatformObjectFramework tools;

  @version 9.2
  @author Allan Bowe
**/

%macro mf_loc(loc);
%let loc=%upcase(&loc);
%local root;

%if &loc=POF or &loc=PLATFORMOBJECTFRAMEWORK %then %do;
  %let root=%substr(%sysget(SASROOT),1,%index(%sysget(SASROOT),SASFoundation)-2);
  %let root=&root/SASPlatformObjectFramework/&sysver;
  %put Batch tools located at: &root;
  &root
%end;
%else %if &loc=VIYACONFIG %then %do;
  %let root=/opt/sas/viya/config;
  %put Viya Config located at: &root;
  &root
%end;

%mend mf_loc;
/**
  @file
  @brief Creates a directory, including any intermediate directories
  @details Works on windows and unix environments via dcreate function.
Usage:

    %mf_mkdir(/some/path/name)


  @param dir relative or absolute pathname.  Unquoted.
  @version 9.2

**/

%macro mf_mkdir(dir
)/*/STORE SOURCE*/;

  %local lastchar child parent;

  %let lastchar = %substr(&dir, %length(&dir));
  %if (%bquote(&lastchar) eq %str(:)) %then %do;
    /* Cannot create drive mappings */
    %return;
  %end;

  %if (%bquote(&lastchar)=%str(/)) or (%bquote(&lastchar)=%str(\)) %then %do;
    /* last char is a slash */
    %if (%length(&dir) eq 1) %then %do;
      /* one single slash - root location is assumed to exist */
      %return;
    %end;
    %else %do;
      /* strip last slash */
      %let dir = %substr(&dir, 1, %length(&dir)-1);
    %end;
  %end;

  %if (%sysfunc(fileexist(%bquote(&dir))) = 0) %then %do;
    /* directory does not exist so prepare to create */
    /* first get the childmost directory */
    %let child = %scan(&dir, -1, %str(/\:));

    /*
      If child name = path name then there are no parents to create. Else
      they must be recursively scanned.
    */

    %if (%length(&dir) gt %length(&child)) %then %do;
      %let parent = %substr(&dir, 1, %length(&dir)-%length(&child));
      %mf_mkdir(&parent)
    %end;

    /*
      Now create the directory.  Complain loudly of any errs.
    */

    %let dname = %sysfunc(dcreate(&child, &parent));
    %if (%bquote(&dname) eq ) %then %do;
      %put %str(ERR)OR: could not create &parent + &child;
      %abort cancel;
    %end;
    %else %do;
      %put Directory created:  &dir;
    %end;
  %end;
  /* exit quietly if directory did exist.*/
%mend mf_mkdir;
/**
  @file mf_mval.sas
  @brief Returns a macro variable value if the variable exists
  @details
  Use this macro to avoid repetitive use of `%if %symexist(MACVAR) %then`
  type logic.
  Usage:

      %if %mf_mval(maynotexist)=itdid %then %do;

  @version 9.2
  @author Allan Bowe
**/

%macro mf_mval(var);
  %if %symexist(&var) %then %do;
    %superq(&var)
  %end;
%mend mf_mval;
/**
  @file
  @brief Returns number of logical (undeleted) observations.
  @details Beware - will not work on external database tables!
  Is just a convenience macro for calling <code> %mf_getattrn()</code>.

        %put Number of observations=%mf_nobs(sashelp.class);

  <h4> SAS Macros </h4>
  @li mf_getattrn.sas

  @param libds library.dataset

  @return output returns result of the attrn value supplied, or log message
    if err.


  @version 9.2
  @author Allan Bowe

**/

%macro mf_nobs(libds
)/*/STORE SOURCE*/;
  %mf_getattrn(&libds,NLOBS)
%mend mf_nobs;/**
  @file mf_trimstr.sas
  @brief Removes character(s) from the end, if they exist
  @details If the designated characters exist at the end of the string, they
  are removed

        %put %mf_trimstr(/blah/,/); * /blah;
        %put %mf_trimstr(/blah/,h); * /blah/;
        %put %mf_trimstr(/blah/,h/);* /bla;

  <h4> SAS Macros </h4>


  @param basestr The string to be modified
  @param trimstr The string to be removed from the end of `basestr`, if it
    exists

  @return output returns result with the value of `trimstr` removed from the end


  @version 9.2
  @author Allan Bowe

**/

%macro mf_trimstr(basestr,trimstr);
%local baselen trimlen trimval;

/* return if basestr is shorter than trimstr (or 0) */
%let baselen=%length(%superq(basestr));
%let trimlen=%length(%superq(trimstr));
%if &baselen < &trimlen or &baselen=0 %then %return;

/* obtain the characters from the end of basestr */
%let trimval=%qsubstr(%superq(basestr)
  ,%length(%superq(basestr))-&trimlen+1
  ,&trimlen);

/* compare and if matching, chop it off! */
%if %superq(basestr)=%superq(trimstr) %then %do;
  %return;
%end;
%else %if %superq(trimval)=%superq(trimstr) %then %do;
  %qsubstr(%superq(basestr),1,%length(%superq(basestr))-&trimlen)
%end;
%else %do;
  &basestr
%end;

%mend mf_trimstr;/**
  @file
  @brief Creates a unique ID based on system time in friendly format
  @details format = YYYYMMDD_HHMMSSmmm_<sysjobid>_<3randomDigits>

        %put %mf_uid();

  @version 9.3
  @author Allan Bowe

**/

%macro mf_uid(
)/*/STORE SOURCE*/;
  %local today now;
  %let today=%sysfunc(today(),yymmddn8.);
  %let now=%sysfunc(compress(%sysfunc(time(),tod12.3),:.));

  &today._&now._&sysjobid._%sysevalf(%sysfunc(ranuni(0))*999,CEIL)

%mend mf_uid;/**
  @file
  @brief Checks if a set of macro variables exist / contain values.
  @details Writes ERROR to log if abortType is SOFT, else will call %mf_abort.
  Usage:

      %let var1=x;
      %let var2=y;
      %put %mf_verifymacvars(var1 var2);

  Returns:
  > 1

  <h4> SAS Macros </h4>
  @li mf_abort.sas

  @param verifyvars space separated list of macro variable names
  @param makeupcase= set to YES to convert all variable VALUES to
    uppercase.
  @param mAbort= Abort Type.  Default is SOFT (writes err to log).
    Set to any other value to call mf_abort (which can be configured to abort in
    various fashions according to context).

  @warning will not be able to verify the following variables due to
    naming clash!
      - verifyVars
      - verifyVar
      - verifyIterator
      - makeUpcase

  @version 9.2
  @author Allan Bowe

**/


%macro mf_verifymacvars(
    verifyVars  /* list of macro variable NAMES */
    ,makeUpcase=NO  /* set to YES to make all the variable VALUES uppercase */
    ,mAbort=SOFT
)/*/STORE SOURCE*/;

  %local verifyIterator verifyVar abortmsg;
  %do verifyIterator=1 %to %sysfunc(countw(&verifyVars,%str( )));
    %let verifyVar=%qscan(&verifyVars,&verifyIterator,%str( ));
    %if not %symexist(&verifyvar) %then %do;
      %let abortmsg= Variable &verifyVar is MISSING;
      %goto exit_err;
    %end;
    %if %length(%trim(&&&verifyVar))=0 %then %do;
      %let abortmsg= Variable &verifyVar is EMPTY;
      %goto exit_err;
    %end;
    %if &makeupcase=YES %then %do;
      %let &verifyVar=%upcase(&&&verifyvar);
    %end;
  %end;

  %goto exit_success;
  %exit_err:
    %if &mAbort=SOFT %then %put %str(ERR)OR: &abortmsg;
    %else %mf_abort(mac=mf_verifymacvars,type=&mabort,msg=&abortmsg);
  %exit_success:

%mend mf_verifymacvars;
/**
  @file
  @brief Returns words that are in both string 1 and string 2
  @details  Compares two space separated strings and returns the words that are
  in both.
  Usage:

      %put %mf_wordsInStr1andStr2(
        Str1=blah sss blaaah brah bram boo
        ,Str2=   blah blaaah brah ssss
      );

  returns:
  > blah blaaah brah

  @param str1= string containing words to extract
  @param str2= used to compare with the extract string

  @warning CASE SENSITIVE!

  @version 9.2
  @author Allan Bowe

**/

%macro mf_wordsInStr1andStr2(
  Str1= /* string containing words to extract */
  ,Str2= /* used to compare with the extract string */
)/*/STORE SOURCE*/;

%local count_base count_extr i i2 extr_word base_word match outvar;
%if %length(&str1)=0 or %length(&str2)=0 %then %do;
  %put %str(WARN)ING: empty string provided!;
  %put base string (str1)= &str1;
  %put compare string (str2) = &str2;
  %return;
%end;
%let count_base=%sysfunc(countw(&Str2));
%let count_extr=%sysfunc(countw(&Str1));

%do i=1 %to &count_extr;
  %let extr_word=%scan(&Str1,&i,%str( ));
  %let match=0;
  %do i2=1 %to &count_base;
    %let base_word=%scan(&Str2,&i2,%str( ));
    %if &extr_word=&base_word %then %let match=1;
  %end;
  %if &match=1 %then %let outvar=&outvar &extr_word;
%end;

  &outvar

%mend mf_wordsInStr1andStr2;

/**
  @file
  @brief Returns words that are in string 1 but not in string 2
  @details  Compares two space separated strings and returns the words that are
  in the first but not in the second.
  Usage:

      %let x= %mf_wordsInStr1ButNotStr2(
        Str1=blah sss blaaah brah bram boo
        ,Str2=   blah blaaah brah ssss
      );

  returns:
  > sss bram boo

  @param str1= string containing words to extract
  @param str2= used to compare with the extract string

  @warning CASE SENSITIVE!

  @version 9.2
  @author Allan Bowe

**/

%macro mf_wordsInStr1ButNotStr2(
  Str1= /* string containing words to extract */
  ,Str2= /* used to compare with the extract string */
)/*/STORE SOURCE*/;

%local count_base count_extr i i2 extr_word base_word match outvar;
%if %length(&str1)=0 or %length(&str2)=0 %then %do;
  %put %str(WARN)ING: empty string provided!;
  %put base string (str1)= &str1;
  %put compare string (str2) = &str2;
  %return;
%end;
%let count_base=%sysfunc(countw(&Str2));
%let count_extr=%sysfunc(countw(&Str1));

%do i=1 %to &count_extr;
  %let extr_word=%scan(&Str1,&i,%str( ));
  %let match=0;
  %do i2=1 %to &count_base;
    %let base_word=%scan(&Str2,&i2,%str( ));
    %if &extr_word=&base_word %then %let match=1;
  %end;
  %if &match=0 %then %let outvar=&outvar &extr_word;
%end;

  &outvar

%mend mf_wordsInStr1ButNotStr2;

/**
  @file
  @brief Creates a text file using pure macro
  @details Creates a text file of up to 10 lines.  If further lines are
    desired, feel free to [create an issue](
    https://github.com/sasjs/core/issues/new), or make a pull request!

    The use of PARMBUFF was considered for this macro, but it would have made
    things problematic for writing lines containing commas.

    Usage:

        %mf_writefile(&sasjswork/myfile.txt,l1=some content,l2=more content)
        data _null_;
          infile "&sasjswork/myfile.txt";
          input;
          list;
        run;

  @param [in] fpath Full path to file to be created or appended to
  @param [in] mode= (O) Available options are A or O as follows:
    @li A APPEND mode, writes new records after the current end of the file.
    @li O OUTPUT mode, writes new records from the beginning of the file.
  @param [in] l1= First line
  @param [in] l2= Second line (etc through to l10)

  <h4> Related Macros </h4>
  @li mf_writefile.test.sas

  @version 9.2
  @author Allan Bowe
**/
/** @cond */

%macro mf_writefile(fpath,mode=O,l1=,l2=,l3=,l4=,l5=,l6=,l7=,l8=,l9=,l10=
)/*/STORE SOURCE*/;
%local fref rc fid i total_lines;

/* find number of lines by reference to first non-blank param */
%do i=10 %to 1 %by -1;
  %if %str(&&l&i) ne %str() %then %goto continue;
%end;
%continue:
%let total_lines=&i;

%if %sysfunc(filename(fref,&fpath)) ne 0 %then %do;
  %put &=fref &=fpath;
  %put %str(ERR)OR: %sysfunc(sysmsg());
  %return;
%end;

%let fid=%sysfunc(fopen(&fref,&mode));

%if &fid=0 %then %do;
  %put %str(ERR)OR: %sysfunc(sysmsg());
  %return;
%end;

%do i=1 %to &total_lines;
  %let rc=%sysfunc(fput(&fid, &&l&i));
  %let rc=%sysfunc(fwrite(&fid));
%end;
%let rc=%sysfunc(fclose(&fid));
%let rc=%sysfunc(filename(&fref));

%mend mf_writefile;
/** @endcond *//**
  @file
  @brief abort gracefully according to context
  @details Configures an abort mechanism according to site specific policies or
    the particulars of an environment.  For instance, can stream custom
    results back to the client in an STP Web App context, or completely stop
    in the case of a batch run.  For STP sessions

  The method used varies according to the context.  Important points:

  @li should not use endsas or abort cancel in 9.4m3 environments as this can
    cause hung multibridge sessions and result in a frozen STP server
  @li should not use endsas in viya 3.5 as this destroys the session and cannot
    fetch results (although both mv_getjoblog.sas and the @sasjs/adapter will
    recognise this and fetch the log of the parent session instead)
  @li STP environments must finish cleanly to avoid the log being sent to
    _webout.  To assist with this, we also run stpsrvset('program error', 0)
    and set SYSCC=0.  We take a unique "soft abort" approach - we open a macro
    but don't close it!  This works everywhere EXCEPT inside a \%include inside
    a macro.  For that, we recommend you use mp_include.sas to perform the
    include, and then call \%mp_abort(mode=INCLUDE) from the source program (ie,
    OUTSIDE of the top-parent macro).


  @param mac= to contain the name of the calling macro
  @param msg= message to be returned
  @param iftrue= supply a condition under which the macro should be executed.
  @param errds= (work.mp_abort_errds) There is no clean way to end a process
    within a %include called within a macro.  Furthermore, there is no way to
    test if a macro is called within a %include.  To handle this particular
    scenario, the %include should be switched for the mp_include.sas macro.
    This provides an indicator that we are running a macro within a \%include
    (`_SYSINCLUDEFILEDEVICE`) and allows us to provide a dataset with the abort
    values (msg, mac).
    We can then run an abort cancel FILE to stop the include running, and pass
    the dataset back to the calling program to run a regular \%mp_abort().
    The dataset will contain the following fields:
    @li iftrue (1=1)
    @li msg (the message)
    @li mac (the mac param)

  @param mode= (REGULAR) If mode=INCLUDE then the &errds dataset is checked for
    an abort status.
    Valid values:
    @li REGULAR (default)
    @li INCLUDE

  <h4> Related Macros </h4>
  @li mp_include.sas

  @version 9.4
  @author Allan Bowe
  @cond
**/

%macro mp_abort(mac=mp_abort.sas, type=, msg=, iftrue=%str(1=1)
  , errds=work.mp_abort_errds
  , mode=REGULAR
)/*/STORE SOURCE*/;

  %global sysprocessmode sysprocessname;

  %if not(%eval(%unquote(&iftrue))) %then %return;

  %put NOTE: ///  mp_abort macro executing //;
  %if %length(&mac)>0 %then %put NOTE- called by &mac;
  %put NOTE - &msg;

  %if %symexist(_SYSINCLUDEFILEDEVICE) %then %do;
    %if "*&_SYSINCLUDEFILEDEVICE*" ne "**" %then %do;
      data &errds;
        iftrue='1=1';
        length mac $100 msg $5000;
        mac=symget('mac');
        msg=symget('msg');
      run;
      data _null_;
        abort cancel FILE;
      run;
      %return;
    %end;
  %end;

  /* Stored Process Server web app context */
  %if %symexist(_metaperson)
    or "&SYSPROCESSNAME "="Compute Server "
    or &mode=INCLUDE
  %then %do;
    options obs=max replace nosyntaxcheck mprint;
    %if &mode=INCLUDE %then %do;
      %if %sysfunc(exist(&errds))=1 %then %do;
        data _null_;
          set &errds;
          call symputx('iftrue',iftrue,'l');
          call symputx('mac',mac,'l');
          call symputx('msg',msg,'l');
          putlog (_all_)(=);
        run;
        %if (&iftrue)=0 %then %return;
      %end;
      %else %do;
        %put &sysmacroname: No include errors found;
        %return;
      %end;
    %end;

    /* extract log errs / warns, if exist */
    %local logloc logline;
    %global logmsg; /* capture global messages */
    %if %symexist(SYSPRINTTOLOG) %then %let logloc=&SYSPRINTTOLOG;
    %else %let logloc=%qsysfunc(getoption(LOG));
    proc printto log=log;run;
    %if %length(&logloc)>0 %then %do;
      %let logline=0;
      data _null_;
        infile &logloc lrecl=5000;
        input; putlog _infile_;
        i=1;
        retain logonce 0;
        if (
            _infile_=:"%str(WARN)ING" or _infile_=:"%str(ERR)OR"
          ) and logonce=0 then
        do;
          call symputx('logline',_n_);
          logonce+1;
        end;
      run;
      /* capture log including lines BEFORE the err */
      %if &logline>0 %then %do;
        data _null_;
          infile &logloc lrecl=5000;
          input;
          i=1;
          stoploop=0;
          if _n_ ge &logline-15 and stoploop=0 then do until (i>22);
            call symputx('logmsg',catx('\n',symget('logmsg'),_infile_));
            input;
            i+1;
            stoploop=1;
          end;
          if stoploop=1 then stop;
        run;
      %end;
    %end;

    %if %symexist(SYS_JES_JOB_URI) %then %do;
      /* setup webout */
      OPTIONS NOBOMFILE;
      %if "X&SYS_JES_JOB_URI.X"="XX" %then %do;
          filename _webout temp lrecl=999999 mod;
      %end;
      %else %do;
        filename _webout filesrvc parenturi="&SYS_JES_JOB_URI"
          name="_webout.json" lrecl=999999 mod;
      %end;
    %end;

    /* send response in SASjs JSON format */
    data _null_;
      file _webout mod lrecl=32000 encoding='utf-8';
      length msg $32767 ;
      sasdatetime=datetime();
      msg=cats(symget('msg'),'\n\nLog Extract:\n',symget('logmsg'));
      /* escape the quotes */
      msg=tranwrd(msg,'"','\"');
      /* ditch the CRLFs as chrome complains */
      msg=compress(msg,,'kw');
      /* quote without quoting the quotes (which are escaped instead) */
      msg=cats('"',msg,'"');
      if symexist('_debug') then debug=quote(trim(symget('_debug')));
      else debug='""';
      put '>>weboutBEGIN<<';
      put '{"START_DTTM" : "' "%sysfunc(datetime(),datetime20.3)" '"';
      put ',"sasjsAbort" : [{';
      put ' "MSG":' msg ;
      put ' ,"MAC": "' "&mac" '"}]';
      put ",""SYSUSERID"" : ""&sysuserid"" ";
      put ',"_DEBUG":' debug ;
      if symexist('_metauser') then do;
        _METAUSER=quote(trim(symget('_METAUSER')));
        put ",""_METAUSER"": " _METAUSER;
        _METAPERSON=quote(trim(symget('_METAPERSON')));
        put ',"_METAPERSON": ' _METAPERSON;
      end;
      if symexist('SYS_JES_JOB_URI') then do;
        SYS_JES_JOB_URI=quote(trim(symget('SYS_JES_JOB_URI')));
        put ',"SYS_JES_JOB_URI": ' SYS_JES_JOB_URI;
      end;
      _PROGRAM=quote(trim(resolve(symget('_PROGRAM'))));
      put ',"_PROGRAM" : ' _PROGRAM ;
      put ",""SYSCC"" : ""&syscc"" ";
      syserrortext=quote(trim(symget('syserrortext')));
      put ",""SYSERRORTEXT"" : " syserrortext;
      put ",""SYSHOSTNAME"" : ""&syshostname"" ";
      put ",""SYSJOBID"" : ""&sysjobid"" ";
      put ",""SYSSCPL"" : ""&sysscpl"" ";
      put ",""SYSSITE"" : ""&syssite"" ";
      sysvlong=quote(trim(symget('sysvlong')));
      put ',"SYSVLONG" : ' sysvlong;
      syswarningtext=quote(trim(symget('syswarningtext')));
      put ",""SYSWARNINGTEXT"" : " syswarningtext;
      put ',"END_DTTM" : "' "%sysfunc(datetime(),datetime20.3)" '" ';
      put "}" @;
      put '>>weboutEND<<';
    run;

    %put _all_;

    %if "&sysprocessmode " = "SAS Stored Process Server " %then %do;
      data _null_;
        putlog 'stpsrvset program err and syscc';
        rc=stpsrvset('program error', 0);
        call symputx("syscc",0,"g");
      run;
      /**
        * endsas kills 9.4m3 deployments by orphaning multibridges.
        * Abort variants are ungraceful (non zero return code)
        * This approach lets SAS run silently until the end :-)
        * Caution - fails when called within a %include within a macro
        * Use mp_include() to handle this.
        */
      filename skip temp;
      data _null_;
        file skip;
        put '%macro skip();';
        comment '%mend skip; -> fix lint ';
        put '%macro skippy();';
        comment '%mend skippy; -> fix lint ';
      run;
      %inc skip;
    %end;
    %else %if "&sysprocessmode " = "SAS Compute Server " %then %do;
      /* endsas kills the session making it harder to fetch results */
      data _null_;
        syswarningtext=symget('syswarningtext');
        syserrortext=symget('syserrortext');
        abort_msg=symget('msg');
        syscc=symget('syscc');
        sysuserid=symget('sysuserid');
        iftrue=symget('iftrue');
        put (_all_)(/=);
        call symputx('syscc',0);
        abort cancel nolist;
      run;
    %end;
    %else %do;
      %abort cancel;
    %end;
  %end;
  %else %do;
    %put _all_;
    %abort cancel;
  %end;
%mend mp_abort;

/** @endcond *//**
  @file
  @brief Append (concatenate) two or more files.
  @details Will append one more more `appendrefs` (filerefs) to a `baseref`.
  Uses a binary mechanism, so will work with any file type.  For that reason -
  use with care!   And supply your own trailing carriage returns in each file..

  Usage:

        filename tmp1 temp;
        filename tmp2 temp;
        filename tmp3 temp;
        data _null_; file tmp1; put 'base file';
        data _null_; file tmp2; put 'append1';
        data _null_; file tmp3; put 'append2';
        run;
        %mp_appendfile(baseref=tmp1, appendrefs=tmp2 tmp3)


  @param [in] baseref= Fileref of the base file (should exist)
  @param [in] appendrefs= One or more filerefs to be appended to the base
    fileref.  Space separated.

  @version 9.2
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mp_binarycopy.sas


**/

%macro mp_appendfile(
  baseref=0,
  appendrefs=0
)/*/STORE SOURCE*/;

%mp_abort(iftrue= (&baseref=0)
  ,mac=&sysmacroname
  ,msg=%str(Baseref NOT specified!)
)
%mp_abort(iftrue= (&appendrefs=0)
  ,mac=&sysmacroname
  ,msg=%str(Appendrefs NOT specified!)
)

%local i;
%do i=1 %to %sysfunc(countw(&appendrefs));
  %mp_abort(iftrue= (&syscc>0)
    ,mac=&sysmacroname
    ,msg=%str(syscc=&syscc)
  )
  %mp_binarycopy(inref=%scan(&appendrefs,&i), outref=&baseref, mode=APPEND)
%end;

%mend mp_appendfile;/**
  @file
  @brief Apply a set of formats to a table
  @details Applies a set of formats to the metadata of one or more SAS datasets.
    Can be used to migrate formats from one table to another.  The input table
    must contain the following columns:

    @li lib - the libref of the table to be updated
    @li ds - the dataset to be updated
    @li var - the variable to be updated
    @li fmt - the format to apply.  Missing or default ($CHAR, 8.) formats are
      ignored.

  The macro will abort in the following scenarios:

    @li Libref not assigned
    @li Dataset does not exist
    @li Input table contains null or invalid values

  Example usage:

      data work.example;
        set sashelp.prdsale;
        format _all_ clear;
      run;

      %mp_getcols(sashelp.prdsale,outds=work.cols)

      data work.cols2;
        set work.cols;
        lib='WORK';
        ds='EXAMPLE';
        var=name;
        fmt=format;
        keep lib ds var fmt;
      run;

      %mp_applyformats(work.cols2)

  @param [in] inds The input dataset containing the formats to apply (and where
    to apply them).  Example structure:
  |LIB:$8.|DS:$32.|VAR:$32.|FMT:$49.|
  |---|---|---|---|
  |`WORK `|`EXAMPLE `|`ACTUAL `|`DOLLAR12.2 `|
  |`WORK `|`EXAMPLE `|`COUNTRY `|`$CHAR10. `|
  |`WORK `|`EXAMPLE `|`DIVISION `|`$CHAR10. `|
  |`WORK `|`EXAMPLE `|`MONTH `|`MONNAME3. `|
  |`WORK `|`EXAMPLE `|`PREDICT `|`DOLLAR12.2 `|
  |`WORK `|`EXAMPLE `|`PRODTYPE `|`$CHAR10. `|
  |`WORK `|`EXAMPLE `|`PRODUCT `|`$CHAR10. `|
  |`WORK `|`EXAMPLE `|`QUARTER `|`8. `|
  |`WORK `|`EXAMPLE `|`REGION `|`$CHAR10. `|
  |`WORK `|`EXAMPLE `|`YEAR `|`8. `|

  @param [out] errds= (0) Provide a libds reference here to export the
    error messages to a table.  In this case, they will not be printed to the
    log.

  <h4> SAS Macros </h4>
  @li mf_getengine.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquename.sas
  @li mf_nobs.sas
  @li mp_validatecol.sas


  <h4> Related Macros </h4>
  @li mp_getformats.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_applyformats(inds,errds=0
)/*/STORE SOURCE*/;
%local outds liblist i engine lib msg ;

/**
  * Validations
  */
proc sort data=&inds;
  by lib ds var fmt;
run;

%if &errds=0 %then %let outds=%mf_getuniquename(prefix=mp_applyformats);
%else %let outds=&errds;

data &outds;
  set &inds;
  where fmt not in ('','.', '$', '$CHAR.','8.');
  length msg $128;
  by lib ds var fmt;
  if libref(lib) ne 0 then do;
    msg=catx(' ','libref',lib,'is not assigned!');
    %if &errds=0 %then %do;
      putlog "%str(ERR)OR: " msg;
    %end;
    output;
    return;
  end;
  if exist(cats(lib,'.',ds)) ne 1 then do;
    msg=catx(' ','libds',lib,'.',ds,'does not exist!');
    %if &errds=0 %then %do;
      putlog "%str(ERR)OR: " msg;
    %end;
    output;
    return;
  end;
  %mp_validatecol(fmt,FORMAT,is_fmt)
  if is_fmt=0 then do;
    msg=catx(' ','format',fmt,'on libds',lib,'.',ds,'.',var,'is not valid!');
    %if &errds=0 %then %do;
      putlog "%str(ERR)OR: " msg;
    %end;
    output;
    return;
  end;

  if first.ds then do;
    retain dsid;
    dsid=open(cats(lib,'.',ds));
    if dsid=0 then do;
      msg=catx(' ','libds',lib,'.',ds,' could not be opened!');
      %if &errds=0 %then %do;
        putlog "%str(ERR)OR: " msg;
      %end;
      output;
      return;
    end;
    if varnum(dsid,var)<1 then do;
      msg=catx(' ','Variable',lib,'.',ds,'.',var,' was not found!');
      %if &errds=0 %then %do;
        putlog "%str(ERR)OR: " msg;
      %end;
      output;
    end;
  end;
  if last.ds then rc=close(dsid);
run;

proc sql noprint;
select distinct lib into: liblist separated by ' ' from &inds;
%put &=liblist;
%do i=1 %to %sysfunc(countw(&liblist));
  %let lib=%scan(&liblist,1);
  %let engine=%mf_getengine(&lib);
  %if &engine ne V9 and &engine ne BASE %then %do;
    %let msg=&lib has &engine engine - formats cannot be applied;
    proc sql;
    insert into &outds set lib="&lib",ds="_all_",var="_all", msg="&msg" ;
    %if &errds=0 %then %put %str(ERR)OR: &msg;
  %end;
%end;

%if %mf_nobs(&outds)>0 %then %return;

/**
  * Validations complete - now apply the actual formats!
  */
%let fref=%mf_getuniquefileref();
data _null_;
  set &inds;
  by lib ds var fmt;
  where fmt not in ('','.', '$', '$CHAR.','8.');
  file &fref;
  if first.lib then put 'proc datasets nolist lib=' lib ';';
  if first.ds then put '  modify ' ds ';';
  put '    format ' var fmt ';';
  if last.ds then put '  run;';
  if last.lib then put 'quit;';
run;

%inc &fref/source2;

%if &errds=0 %then %do;
  proc sql;
  drop table &outds;
%end;

%mend mp_applyformats;/**
  @file
  @brief Generic assertion
  @details Useful in the context of writing sasjs tests.  The results of the
  test are _appended_ to the &outds. table.

  Example usage:

      %mp_assert(iftrue=(1=1),
        desc=Obviously true
      )

      %mp_assert(iftrue=(1=0),
        desc=Will fail
      )

  @param [in] iftrue= (1=1) A condition where, if true, the test is a PASS.
  Else, the test is a fail.

  @param [in] desc= (Testing observations) The user provided test description
  @param [out] outds= (work.test_results) The output dataset to contain the
  results.  If it does not exist, it will be created, with the following format:
  |TEST_DESCRIPTION:$256|TEST_RESULT:$4|TEST_COMMENTS:$256|
  |---|---|---|
  |User Provided description|PASS|Column &inds contained ALL columns|

  @version 9.2
  @author Allan Bowe

**/

%macro mp_assert(iftrue=(1=1),
  desc=0,
  outds=work.test_results
)/*/STORE SOURCE*/;

  data ;
    length test_description $256 test_result $4 test_comments $256;
    test_description=symget('desc');
    test_comments="&sysmacroname: Test result of "!!symget('iftrue');
  %if %eval(%unquote(&iftrue)) %then %do;
    test_result='PASS';
  %end;
  %else %do;
    test_result='FAIL';
  %end;
  run;

  %local ds ;
  %let ds=&syslast;
  proc append base=&outds data=&ds;
  run;
  proc sql;
  drop table &ds;

%mend mp_assert;/**
  @file
  @brief Asserts the existence (or not) of columns
  @details Useful in the context of writing sasjs tests.  The results of the
  test are _appended_ to the &outds. table.

  Example usage:

      %mp_assertcols(sashelp.class,
        cols=name age sex,
        test=ALL,
        desc=check all columns exist
      )

      %mp_assertcols(sashelp.class,
        cols=a b c,
        test=NONE
      )

      %mp_assertcols(sashelp.class,
        cols=age depth,
        test=ANY
      )

  <h4> SAS Macros </h4>
  @li mf_existds.sas
  @li mf_existvarlist.sas
  @li mf_getvarlist.sas
  @li mf_wordsinstr1butnotstr2.sas
  @li mp_abort.sas


  @param [in] inds The input library.dataset to test for values
  @param [in] cols= The list of columns to check for
  @param [in] desc= (Testing observations) The user provided test description
  @param [in] test= (ALL) The test to apply.  Valid values are:
    @li ALL - Test is a PASS if ALL columns exist in &inds
    @li ANY - Test is a PASS if ANY of the columns exist in &inds
    @li NONE - Test is a PASS if NONE of the columns exist in &inds
  @param [out] outds= (work.test_results) The output dataset to contain the
  results.  If it does not exist, it will be created, with the following format:
  |TEST_DESCRIPTION:$256|TEST_RESULT:$4|TEST_COMMENTS:$256|
  |---|---|---|
  |User Provided description|PASS|Column &inds contained ALL columns|


  <h4> Related Macros </h4>
  @li mp_assertdsobs.sas
  @li mp_assertcolvals.sas
  @li mp_assertdsobs.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_assertcols(inds,
  cols=0,
  test=ALL,
  desc=0,
  outds=work.test_results
)/*/STORE SOURCE*/;

  %mp_abort(iftrue= (&syscc ne 0)
    ,mac=&sysmacroname
    ,msg=%str(syscc=&syscc - on macro entry)
  )

  %local lib ds ;
  %let lib=%scan(&inds,1,%str(.));
  %let ds=%scan(&inds,2,%str(.));
  %let cols=%upcase(&cols);

  %mp_abort(iftrue= (%mf_existds(&lib..&ds)=0)
    ,mac=&sysmacroname
    ,msg=%str(&lib..&ds not found!)
  )

  %mp_abort(iftrue= (&cols=0)
    ,mac=&sysmacroname
    ,msg=%str(No cols provided)
  )


  %let test=%upcase(&test);

  %if &test ne ANY and &test ne ALL and &test ne NONE %then %do;
    %mp_abort(
      mac=&sysmacroname,
      msg=%str(Invalid test - &test)
    )
  %end;

  /**
    * now do the actual test!
    */
  %local result;
  %if %mf_existVarList(&inds,&cols)=1 %then %let result=ALL;
  %else %do;
    %local targetcols compare;
    %let targetcols=%upcase(%mf_getvarlist(&inds));
    %let compare=%mf_wordsinstr1butnotstr2(
        Str1=&cols,
        Str2=&targetcols
      );
    %if %cmpres(&compare)=%cmpres(&cols) %then %let result=NONE;
    %else %let result=SOME;
  %end;

  data;
    length test_description $256 test_result $4 test_comments $256;
    test_description=symget('desc');
    if test_description='0'
    then test_description="Testing &inds for existence of &test of: &cols";

    test_result='FAIL';
    test_comments="&sysmacroname: &inds has &result columns ";
  %if &test=ALL %then %do;
    %if &result=ALL %then %do;
      test_result='PASS';
    %end;
  %end;
  %else %if &test=ANY %then %do;
    %if &result=SOME %then %do;
      test_result='PASS';
    %end;
  %end;
  %else %if &test=NONE %then %do;
    %if &result=NONE %then %do;
      test_result='PASS';
    %end;
  %end;
  %else %do;
    test_comments="&sysmacroname: Unsatisfied test condition - &test";
  %end;
  run;

  %local ds;
  %let ds=&syslast;
  proc append base=&outds data=&ds;
  run;
  proc sql;
  drop table &ds;

%mend mp_assertcols;/**
  @file
  @brief Asserts the values in a column
  @details Useful in the context of writing sasjs tests.  The results of the
  test are _appended_ to the &outds. table.

  Example usage:

      data work.checkds;
        do checkval='Jane','James','Jill';
          output;
        end;
      run;
      %mp_assertcolvals(sashelp.class.name,
        checkvals=work.checkds.checkval,
        desc=At least one value has a match,
        test=ANYVAL
      )

      data work.check;
        do val='M','F';
          output;
        end;
      run;
      %mp_assertcolvals(sashelp.class.sex,
        checkvals=work.check.val,
        desc=All values have a match,
        test=ALLVALS
      )

  <h4> SAS Macros </h4>
  @li mf_existds.sas
  @li mf_getuniquename.sas
  @li mf_nobs.sas
  @li mp_abort.sas


  @param [in] indscol The input library.dataset.column to test for values
  @param [in] checkvals= A library.dataset.column value containing a UNIQUE
    list of values to be compared against the source (indscol).
  @param [in] desc= (Testing observations) The user provided test description
  @param [in] test= (ALLVALS) The test to apply.  Valid values are:
    @li ALLVALS - Test is a PASS if ALL values have a match in checkvals
    @li ANYVAL - Test is a PASS if at least 1 value has a match in checkvals
  @param [out] outds= (work.test_results) The output dataset to contain the
  results.  If it does not exist, it will be created, with the following format:
  |TEST_DESCRIPTION:$256|TEST_RESULT:$4|TEST_COMMENTS:$256|
  |---|---|---|
  |User Provided description|PASS|Column &indscol contained ALL target vals|


  <h4> Related Macros </h4>
  @li mp_assertdsobs.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_assertcolvals(indscol,
  checkvals=0,
  test=ALLVALS,
  desc=mp_assertcolvals - no desc provided,
  outds=work.test_results
)/*/STORE SOURCE*/;

  %mp_abort(iftrue= (&syscc ne 0)
    ,mac=&sysmacroname
    ,msg=%str(syscc=&syscc - on macro entry)
  )

  %local lib ds col clib cds ccol nobs;
  %let lib=%scan(&indscol,1,%str(.));
  %let ds=%scan(&indscol,2,%str(.));
  %let col=%scan(&indscol,3,%str(.));
  %mp_abort(iftrue= (%mf_existds(&lib..&ds)=0)
    ,mac=&sysmacroname
    ,msg=%str(&lib..&ds not found!)
  )

  %mp_abort(iftrue= (&checkvals=0)
    ,mac=&sysmacroname
    ,msg=%str(Set CHECKVALS to a library.dataset.column containing check vals)
  )
  %let clib=%scan(&checkvals,1,%str(.));
  %let cds=%scan(&checkvals,2,%str(.));
  %let ccol=%scan(&checkvals,3,%str(.));
  %mp_abort(iftrue= (%mf_existds(&clib..&cds)=0)
    ,mac=&sysmacroname
    ,msg=%str(&clib..&cds not found!)
  )
  %let nobs=%mf_nobs(&clib..&cds);
  %mp_abort(iftrue= (&nobs=0)
    ,mac=&sysmacroname
    ,msg=%str(&clib..&cds is empty!)
  )

  %let test=%upcase(&test);

  %if &test ne ALLVALS and &test ne ANYVAL %then %do;
    %mp_abort(
      mac=&sysmacroname,
      msg=%str(Invalid test - &test)
    )
  %end;

  %local result orig;
  %let result=-1;
  %let orig=-1;
  proc sql noprint;
  select count(*) into: result
    from &lib..&ds
    where &col not in (
      select &ccol from &clib..&cds
    );
  select count(*) into: orig from &lib..&ds;
  quit;

  %local notfound tmp1 tmp2;
  %let tmp1=%mf_getuniquename();
  %let tmp2=%mf_getuniquename();

  /* this is a bit convoluted - but using sql outobs=10 throws warnings */
  proc sql noprint;
  create view &tmp1 as
    select distinct &col
    from &lib..&ds
    where &col not in (
      select &ccol from &clib..&cds
    );
  data &tmp2;
    set &tmp1;
    if _n_>10 then stop;
  run;
  proc sql;
  select distinct &col  into: notfound separated by ' ' from &tmp2;


  %mp_abort(iftrue= (&syscc ne 0)
    ,mac=&sysmacroname
    ,msg=%str(syscc=&syscc after macro query)
  )

  data;
    length test_description $256 test_result $4 test_comments $256;
    test_description=symget('desc');
    test_result='FAIL';
    test_comments="&sysmacroname: &lib..&ds..&col has &result values "
      !!"not in &clib..&cds..&ccol.. First 10 vals:"!!symget('notfound');
  %if &test=ANYVAL %then %do;
    if &result < &orig then test_result='PASS';
  %end;
  %else %if &test=ALLVALS %then %do;
    if &result=0 then test_result='PASS';
  %end;
  %else %do;
    test_comments="&sysmacroname: Unsatisfied test condition - &test";
  %end;
  run;

  %local ds;
  %let ds=&syslast;
  proc append base=&outds data=&ds;
  run;
  proc sql;
  drop table &ds;

%mend mp_assertcolvals;/**
  @file
  @brief Asserts the number of observations in a dataset
  @details Useful in the context of writing sasjs tests.  The results of the
  test are _appended_ to the &outds. table.

  Example usage:

      %mp_assertdsobs(sashelp.class) %* tests if any observations are present;

      %mp_assertdsobs(sashelp.class,test=ATLEAST 10) %* pass if >9 obs present;

      %mp_assertdsobs(sashelp.class,test=ATMOST 20) %* pass if <21 obs present;

  <h4> SAS Macros </h4>
  @li mf_nobs.sas
  @li mp_abort.sas


  @param [in] inds input dataset to test for presence of observations
  @param [in] desc= (Testing observations) The user provided test description
  @param [in] test= (HASOBS) The test to apply.  Valid values are:
    @li HASOBS - Test is a PASS if the input dataset has any observations
    @li EMPTY - Test is a PASS if input dataset is empty
    @li EQUALS [integer] - Test passes if row count matches the provided integer
    @li ATLEAST [integer] - Test passes if row count is more than or equal to
      the provided integer
    @li ATMOST [integer] - Test passes if row count is less than or equal to
      the provided integer
  @param [out] outds= (work.test_results) The output dataset to contain the
  results.  If it does not exist, it will be created, with the following format:
  |TEST_DESCRIPTION:$256|TEST_RESULT:$4|TEST_COMMENTS:$256|
  |---|---|---|
  |User Provided description|PASS|Dataset &inds has XX obs|

  <h4> Related Macros </h4>
  @li mp_assertcolvals.sas
  @li mp_assert.sas
  @li mp_assertcols.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_assertdsobs(inds,
  test=HASOBS,
  desc=Testing observations,
  outds=work.test_results
)/*/STORE SOURCE*/;

  %local nobs;
  %let nobs=%mf_nobs(&inds);
  %let test=%upcase(&test);

  %if %substr(&test.xxxxx,1,6)=EQUALS %then %do;
    %let val=%scan(&test,2,%str( ));
    %mp_abort(iftrue= (%DATATYP(&val)=CHAR)
      ,mac=&sysmacroname
      ,msg=%str(Invalid test - &test, expected EQUALS [integer])
    )
    %let test=EQUALS;
  %end;
  %else %if %substr(&test.xxxxxxx,1,7)=ATLEAST %then %do;
    %let val=%scan(&test,2,%str( ));
    %mp_abort(iftrue= (%DATATYP(&val)=CHAR)
      ,mac=&sysmacroname
      ,msg=%str(Invalid test - &test, expected ATLEAST [integer])
    )
    %let test=ATLEAST;
  %end;
  %else %if %substr(&test.xxxxxxx,1,7)=ATMOST %then %do;
    %let val=%scan(&test,2,%str( ));
    %mp_abort(iftrue= (%DATATYP(&val)=CHAR)
      ,mac=&sysmacroname
      ,msg=%str(Invalid test - &test, expected ATMOST [integer])
    )
    %let test=ATMOST;
  %end;
  %else %if &test ne HASOBS and &test ne EMPTY %then %do;
    %mp_abort(
      mac=&sysmacroname,
      msg=%str(Invalid test - &test)
    )
  %end;

  data;
    length test_description $256 test_result $4 test_comments $256;
    test_description=symget('desc');
    test_result='FAIL';
    test_comments="&sysmacroname: Dataset &inds has &nobs observations.";
    test_comments=test_comments!!" Test was "!!symget('test');
  %if &test=HASOBS %then %do;
    if &nobs>0 then test_result='PASS';
  %end;
  %else %if &test=EMPTY %then %do;
    if &nobs=0 then test_result='PASS';
  %end;
  %else %if &test=EQUALS %then %do;
    if &nobs=&val then test_result='PASS';
  %end;
  %else %if &test=ATLEAST %then %do;
    if &nobs ge &val then test_result='PASS';
  %end;
  %else %if &test=ATMOST %then %do;
    if &nobs le &val then test_result='PASS';
  %end;
  %else %do;
    test_comments="&sysmacroname: Unsatisfied test condition - &test";
  %end;
  run;

  %local ds;
  %let ds=&syslast;

  proc append base=&outds data=&ds;
  run;

  proc sql;
  drop table &ds;

%mend mp_assertdsobs;/**
  @file
  @brief Convert a file to/from base64 format
  @details Creates a new version of a file either encoded or decoded using
  Base64.  Inspired by this post by Michael Dixon:
  https://support.selerity.com.au/hc/en-us/articles/223345708-Tip-SAS-and-Base64

  Usage:

        filename tmp temp;
        data _null_;
          file tmp;
          put 'base ik ally';
        run;
        %mp_base64copy(inref=tmp, outref=myref, action=ENCODE)

        data _null_;
          infile myref;
          input;
          put _infile_;
        run;

        %mp_base64copy(inref=myref, outref=mynewref, action=DECODE)

        data _null_;
          infile mynewref;
          input;
          put _infile_;
        run;

  @param [in] inref= Fileref of the input file (should exist)
  @param [out] outref= Output fileref. If it does not exist, it is created.
  @param [in] action= (ENCODE) The action to take. Valid values:
    @li ENCODE - Convert the file to base64 format
    @li DECODE - Decode the file from base64 format

  @version 9.2
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas


**/

%macro mp_base64copy(
  inref=0,
  outref=0,
  action=ENCODE
)/*/STORE SOURCE*/;

%let inref=%upcase(&inref);
%let outref=%upcase(&outref);
%let action=%upcase(&action);
%local infound outfound;
%let infound=0;
%let outfound=0;
data _null_;
  set sashelp.vextfl(where=(fileref="&inref" or fileref="&outref"));
  if fileref="&inref" then call symputx('infound',1,'l');
  if fileref="&outref" then call symputx('outfound',1,'l');
run;

%mp_abort(iftrue= (&infound=0)
  ,mac=&sysmacroname
  ,msg=%str(INREF &inref NOT FOUND!)
)
%mp_abort(iftrue= (&outref=0)
  ,mac=&sysmacroname
  ,msg=%str(OUTREF NOT PROVIDED!)
)
%mp_abort(iftrue= (&action ne ENCODE and &action ne DECODE)
  ,mac=&sysmacroname
  ,msg=%str(Invalid action! Should be ENCODE OR DECODE)
)

%if &outfound=0 %then %do;
  filename &outref temp lrecl=2097088;
%end;

%if &action=ENCODE %then %do;
  data _null_;
    length b64 $ 76 line $ 57;
    retain line "";
    infile &inref recfm=F lrecl= 1 end=eof;
    input @1 stream $char1.;
    file &outref recfm=N;
    substr(line,(_N_-(CEIL(_N_/57)-1)*57),1) = byte(rank(stream));
    if mod(_N_,57)=0 or EOF then do;
      if eof then b64=put(trim(line),$base64X76.);
      else b64=put(line, $base64X76.);
      put b64 + (-1) @;
      line="";
    end;
  run;
%end;
%else %if &action=DECODE %then %do;
  data _null_;
    length filein 8 fileout 8;
    filein = fopen("&inref",'I',4,'B');
    fileout = fopen("&outref",'O',3,'B');
    char= '20'x;
    do while(fread(filein)=0);
      length raw $4;
      do i=1 to 4;
        rc=fget(filein,char,1);
        substr(raw,i,1)=char;
      end;
      rc = fput(fileout,input(raw,$base64X4.));
      rc = fwrite(fileout);
    end;
    rc = fclose(filein);
    rc = fclose(fileout);
  run;
%end;

%mend mp_base64copy;/**
  @file
  @brief Copy any file using binary input / output streams
  @details Reads in a file byte by byte and writes it back out.  Is an
  os-independent method to copy files.  In case of naming collision, the
  default filerefs can be modified.
  Based on:
  https://stackoverflow.com/questions/13046116/using-sas-to-copy-a-text-file

        %mp_binarycopy(inloc="/home/me/blah.txt", outref=_webout)

  To append to a file, use the mode option, eg:

      filename tmp1 temp;
      filename tmp2 temp;
      data _null_;
        file tmp1;
        put 'stacking';
      run;

      %mp_binarycopy(inref=tmp1, outref=tmp2, mode=APPEND)
      %mp_binarycopy(inref=tmp1, outref=tmp2, mode=APPEND)


  @param [in] inloc quoted "path/and/filename.ext" of the file to be copied
  @param [out] outloc quoted "path/and/filename.ext" of the file to be created
  @param [in] inref (____in) If provided, this fileref will take precedence over
    the `inloc` parameter
  @param [out] outref (____in) If provided, this fileref will take precedence
    over the `outloc` parameter.  It must already exist!
  @param [in] mode (CREATE) Valid values:
    @li CREATE - Create the file (even if it already exists)
    @li APPEND - Append to the file (don't overwrite)

  @returns nothing

  @version 9.2

**/

%macro mp_binarycopy(
    inloc=           /* full path and filename of the object to be copied */
    ,outloc=          /* full path and filename of object to be created */
    ,inref=____in   /* override default to use own filerefs */
    ,outref=____out /* override default to use own filerefs */
    ,mode=CREATE
)/*/STORE SOURCE*/;
  %local mod outmode;
  %if &mode=APPEND %then %do;
    %let mod=mod;
    %let outmode='a';
  %end;
  %else %do;
    %let outmode='o';
  %end;
  /* these IN and OUT filerefs can point to anything */
  %if &inref = ____in %then %do;
    filename &inref &inloc lrecl=1048576 ;
  %end;
  %if &outref=____out %then %do;
    filename &outref &outloc lrecl=1048576 &mod;
  %end;

  /* copy the file byte-for-byte  */
  data _null_;
    length filein 8 fileid 8;
    filein = fopen("&inref",'I',1,'B');
    fileid = fopen("&outref",&outmode,1,'B');
    rec = '20'x;
    do while(fread(filein)=0);
      rc = fget(filein,rec,1);
      rc = fput(fileid, rec);
      rc =fwrite(fileid);
    end;
    rc = fclose(filein);
    rc = fclose(fileid);
  run;
  %if &inref = ____in %then %do;
    filename &inref clear;
  %end;
  %if &outref=____out %then %do;
    filename &outref clear;
  %end;
%mend mp_binarycopy;/**
  @file mp_cleancsv.sas
  @brief Fixes embedded cr / lf / crlf in CSV
  @details CSVs will sometimes contain lf or crlf within quotes (eg when
  saved by excel).  When the termstr is ALSO lf or crlf that can be tricky
  to process using SAS defaults.
  This macro converts any csv to follow the convention of a windows excel file,
  applying CRLF line endings and converting embedded cr and crlf to lf.

  usage:

      fileref mycsv "/path/your/csv";
      %mp_cleancsv(in=mycsv,out=/path/new.csv)

  @param in= provide path or fileref to input csv
  @param out= output path or fileref to output csv
  @param qchar= quote char - hex code 22 is the double quote.

  @version 9.2
  @author Allan Bowe
  @cond
**/

%macro mp_cleancsv(in=NOTPROVIDED,out=NOTPROVIDED,qchar='22'x);
%if "&in"="NOTPROVIDED" or "&out"="NOTPROVIDED" %then %do;
  %put %str(ERR)OR: Please provide valid input (&in) & output (&out) locations;
  %return;
%end;

/* presence of a period(.) indicates a physical location */
%if %index(&in,.) %then %let in="&in";
%if %index(&out,.) %then %let out="&out";

/**
  * convert all cr and crlf within quotes to lf
  * convert all other cr or lf to crlf
  */
  data _null_;
    infile &in recfm=n ;
    file &out recfm=n;
    retain isq iscrlf 0 qchar &qchar;
    input inchar $char1. ;
    if inchar=qchar then isq = mod(isq+1,2);
    if isq then do;
      /* inside a quote change cr and crlf to lf */
      if inchar='0D'x then do;
        put '0A'x;
        input inchar $char1.;
        if inchar ne '0A'x then do;
          put inchar $char1.;
          if inchar=qchar then isq = mod(isq+1,2);
        end;
      end;
      else put inchar $char1.;
    end;
    else do;
      /* outside a quote, change cr and lf to crlf */
      if inchar='0D'x then do;
        put '0D0A'x;
        input inchar $char1.;
        if inchar ne '0A'x then do;
          put inchar $char1.;
          if inchar=qchar then isq = mod(isq+1,2);
        end;
      end;
      else if inchar='0A'x then put '0D0A'x;
      else put inchar $char1.;
    end;
  run;
%mend mp_cleancsv;
/** @endcond *//**
  @file
  @brief A macro to recursively copy a directory
  @details Performs a recursive directory listing then works from top to bottom
    copying files and creating subdirectories.

  Usage:

      %let rootdir=%sysfunc(pathname(work))/demo;
      %let copydir=%sysfunc(pathname(work))/demo_copy;
      %mf_mkdir(&rootdir)
      %mf_mkdir(&rootdir/subdir)
      %mf_mkdir(&rootdir/subdir/subsubdir)
      data "&rootdir/subdir/example.sas7bdat";
      run;

      %mp_copyfolder(&rootdir,&copydir)

  @param source Unquoted path to the folder to copy from.
  @param target Unquoted path to the folder to copy to.

  <h4> SAS Macros </h4>
  @li mf_getuniquename.sas
  @li mf_isdir.sas
  @li mf_mkdir.sas
  @li mp_abort.sas
  @li mp_dirlist.sas

  <h4> Related Macros </h4>
  @li mp_copyfolder.test.sas

**/

%macro mp_copyfolder(source,target);

  %mp_abort(iftrue=(%mf_isdir(&source)=0)
    ,mac=&sysmacroname
    ,msg=%str(Source dir does not exist (&source))
  )

  %mf_mkdir(&target)

  %mp_abort(iftrue=(%mf_isdir(&target)=0)
    ,mac=&sysmacroname
    ,msg=%str(Target dir could not be created (&target))
  )

  /* prep temp table */
  %local tempds;
  %let tempds=%mf_getuniquename();

  /* recursive directory listing */
  %mp_dirlist(path=&source,outds=work.&tempds, maxdepth=MAX)

  /* create folders and copy content */
  data _null_;
    length msg $200;
    call missing(msg);
    set work.&tempds;
    if _n_ = 1 then dpos+sum(length(directory),2);
    filepath2="&target/"!!substr(filepath,dpos);
    if file_or_folder='folder' then call execute('%mf_mkdir('!!filepath2!!')');
    else do;
      length fref1 fref2 $8;
      rc1=filename(fref1,filepath,'disk','recfm=n');
      rc2=filename(fref2,filepath2,'disk','recfm=n');
      if fcopy(fref1,fref2) ne 0 then do;
        msg=sysmsg();
        putlog "%str(ERR)OR: Unable to copy " filepath " to " filepath2;
        putlog msg=;
      end;
    end;
    rc=filename(fref1);
    rc=filename(fref2);
  run;

  /* tidy up */
  proc sql;
  drop table work.&tempds;

%mend mp_copyfolder;/**
  @file
  @brief Create the permanent Core tables
  @details Several macros in the [core](https://github.com/sasjs/core) library
    make use of permanent tables.  To avoid duplication in definitions, this
    macro provides a central location for managing the corresponding DDL.

  Example usage:

      %mp_coretable(LOCKTABLE,libds=work.locktable)

  @param [in] table_ref The type of table to create.  Example values:
    @li FILTER_DETAIL - For storing detailed filter values.  Used by
      mp_filterstore.sas.
    @li FILTER_SUMMARY - For storing summary filter values.  Used by
      mp_filterstore.sas.
    @li LOCKANYTABLE - For "locking" tables prior to multipass loads. Used by
      mp_lockanytable.sas
    @li MAXKEYTABLE - For storing the maximum retained key information.  Used
      by mp_retainedkey.sas
  @param [in] libds= (0) The library.dataset reference used to create the table.
    If not provided, then the DDL is simply printed to the log.

  <h4> Related Macros </h4>
  @li mp_filterstore.sas
  @li mp_lockanytable.sas
  @li mp_retainedkey.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_coretable(table_ref,libds=0
)/*/STORE SOURCE*/;
%local outds ;
%let outds=%sysfunc(ifc(&libds=0,_data_,&libds));
proc sql;
%if &table_ref=LOCKTABLE %then %do;
  create table &outds(
      lock_lib char(8),
      lock_ds char(32),
      lock_status_cd char(10) not null,
      lock_user_nm char(100) not null ,
      lock_ref char(200),
      lock_pid char(10),
      lock_start_dttm num format=E8601DT26.6,
      lock_end_dttm num format=E8601DT26.6,
    constraint pk_mp_lockanytable primary key(lock_lib,lock_ds));
%end;
%else %if &table_ref=FILTER_SUMMARY %then %do;
  create table &outds(
      filter_rk num not null,
      filter_hash char(32) not null,
      filter_table char(41) not null,
      processed_dttm num not null format=E8601DT26.6,
    constraint pk_mpe_filteranytable
      primary key(filter_rk));
%end;
%else %if &table_ref=FILTER_DETAIL %then %do;
  create table &outds(
      filter_hash char(32) not null,
      filter_line num not null,
      group_logic char(3) not null,
      subgroup_logic char(3) not null,
      subgroup_id num not null,
      variable_nm varchar(32) not null,
      operator_nm varchar(12) not null,
      raw_value varchar(4000) not null,
      processed_dttm num not null format=E8601DT26.6,
    constraint pk_mpe_filteranytable
      primary key(filter_hash,filter_line));
%end;
%else %if &table_ref=MAXKEYTABLE %then %do;
  create table &outds(
      keytable varchar(41) label='Base table in libref.dataset format',
      keycolumn char(32) format=$32.
        label='The Retained key field containing the key values.',
      max_key num label=
        'Integer representing current max RK or SK value in the KEYTABLE',
      processed_dttm num format=E8601DT26.6
        label='Datetime this value was last updated',
    constraint pk_mpe_maxkeyvalues
        primary key(keytable));
%end;


%if &libds=0 %then %do;
  describe table &syslast;
  drop table &syslast;
%end;
%mend mp_coretable;/**
  @file mp_createconstraints.sas
  @brief Creates constraints
  @details Takes the output from mp_getconstraints.sas as input

        proc sql;
        create table work.example(
          TX_FROM float format=datetime19.,
          DD_TYPE char(16),
          DD_SOURCE char(2048),
          DD_SHORTDESC char(256),
          constraint pk primary key(tx_from, dd_type,dd_source),
          constraint unq unique(tx_from, dd_type),
          constraint nnn not null(DD_SHORTDESC)
        );

      %mp_getconstraints(lib=work,ds=example,outds=work.constraints)
      %mp_deleteconstraints(inds=work.constraints,outds=dropped,execute=YES)
      %mp_createconstraints(inds=work.constraints,outds=created,execute=YES)

  @param inds= The input table containing the constraint info
  @param outds= a table containing the create statements (create_statement column)
  @param execute= `YES|NO` - default is NO. To actually create, use YES.

  <h4> SAS Macros </h4>

  @version 9.2
  @author Allan Bowe

**/

%macro mp_createconstraints(inds=mp_getconstraints
  ,outds=mp_createconstraints
  ,execute=NO
)/*/STORE SOURCE*/;

proc sort data=&inds out=&outds;
  by libref table_name constraint_name;
run;

data &outds;
  set &outds;
  by libref table_name constraint_name;
  length create_statement $500;
  if _n_=1 and "&execute"="YES" then call execute('proc sql;');
  if first.constraint_name then do;
    if constraint_type='PRIMARY' then type='PRIMARY KEY';
    else type=constraint_type;
    create_statement=catx(" ","alter table",libref,".",table_name
      ,"add constraint",constraint_name,type,"(");
    if last.constraint_name then
      create_statement=cats(create_statement,column_name,");");
    else create_statement=cats(create_statement,column_name,",");
    if "&execute"="YES" then call execute(create_statement);
  end;
  else if last.constraint_name then do;
    create_statement=cats(column_name,");");
    if "&execute"="YES" then call execute(create_statement);
  end;
  else do;
    create_statement=cats(column_name,",");
    if "&execute"="YES" then call execute(create_statement);
  end;
  output;
run;

%mend mp_createconstraints;/**
  @file mp_createwebservice.sas
  @brief Create a web service in SAS 9 or Viya
  @details Creates a SASJS ready Stored Process in SAS 9 or Job Execution
  Service in SAS Viya

Usage:

    %* compile macros ;
    filename mc url "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
    %inc mc;

    %* write some code;
    filename ft15f001 temp;
    parmcards4;
        %* fetch any data from frontend ;
        %webout(FETCH)
        data example1 example2;
          set sashelp.class;
        run;
        %* send data back;
        %webout(OPEN)
        %webout(ARR,example1) * Array format, fast, suitable for large tables ;
        %webout(OBJ,example2) * Object format, easier to work with ;
        %webout(CLOSE)
    ;;;;
    %mp_createwebservice(path=/Public/app/common,name=appInit,code=ft15f001,replace=YES)

  <h4> SAS Macros </h4>
  @li mf_getplatform.sas
  @li mm_createwebservice.sas
  @li mv_createwebservice.sas

  @param path= The full folder path where the service will be created
  @param name= Service name.  Avoid spaces.
  @param desc= The description of the service (optional)
  @param precode= Space separated list of filerefs, pointing to the code that
    needs to be attached to the beginning of the service (optional)
  @param code= Space seperated fileref(s) of the actual code to be added
  @param replace= select YES to replace any existing service in that location


  @version 9.2
  @author Allan Bowe

**/

%macro mp_createwebservice(path=HOME
    ,name=initService
    ,precode=
    ,code=ft15f001
    ,desc=This service was created by the mp_createwebservice macro
    ,replace=YES
)/*/STORE SOURCE*/;

%if &syscc ge 4 %then %do;
  %put syscc=&syscc - &sysmacroname will not execute in this state;
  %return;
%end;

%local platform; %let platform=%mf_getplatform();
%if &platform=SASVIYA %then %do;
  %if "&path"="HOME" %then %let path=/Users/&sysuserid/My Folder;
  %mv_createwebservice(path=&path
    ,name=&name
    ,code=&code
    ,precode=&precode
    ,desc=&desc
    ,replace=&replace
  )
%end;
%else %do;
  %if "&path"="HOME" %then %let path=/User Folders/&sysuserid/My Folder;
  %mm_createwebservice(path=&path
    ,name=&name
    ,code=&code
    ,precode=&precode
    ,desc=&desc
    ,replace=&replace
  )
%end;

%mend mp_createwebservice;
/**
  @file mp_csv2ds.sas
  @brief Efficient import of arbitrary CSV using a dataset as template
  @details Used to import relevant columns from a large CSV using
  a dataset to provide the types and lengths.  Assumes that a header
  row is provided, and datarows start on line 2.  Extra columns in
  both the CSV and base dataset are ignored.

  Usage:

      filename mycsv temp;
      data _null_;
        file mycsv;
        put 'name,age,nickname';
        put 'John,48,Jonny';
        put 'Jennifer,23,Jen';
      run;

      %mp_csv2ds(inref=mycsv,outds=myds,baseds=sashelp.class)


  @param inref= fileref to the CSV
  @param outds= output ds (lib.ds format)
  @param view= Set to YES or NO to determine whether the output should be
    a view or not.  Default is NO (not a view).
  @param baseds= Template dataset on which to create the input statement.
    Is used to determine types, lengths, and any informats.

  @version 9.2
  @author Allan Bowe

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_existds.sas

**/

%macro mp_csv2ds(inref=0,outds=0,baseds=0,view=NO);

%mp_abort(iftrue=( &inref=0 )
  ,mac=&sysmacroname
  ,msg=%str(the INREF variable must be provided)
)
%mp_abort(iftrue=( %superq(outds)=0 )
  ,mac=&sysmacroname
  ,msg=%str(the OUTDS variable must be provided)
)
%mp_abort(iftrue=( &baseds=0 )
  ,mac=&sysmacroname
  ,msg=%str(the BASEDS variable must be provided)
)
%mp_abort(iftrue=( &baseds=0 )
  ,mac=&sysmacroname
  ,msg=%str(the BASEDS variable must be provided)
)
%mp_abort(iftrue=( %mf_existds(&baseds)=0 )
  ,mac=&sysmacroname
  ,msg=%str(the BASEDS dataset (&baseds) needs to be assigned, and to exist)
)

/* count rows */
%local hasheader; %let hasheader=0;
data _null_;
  if _N_ > 1 then do;
    call symputx('hasheader',1,'l');
    stop;
  end;
  infile &inref;
  input;
run;
%mp_abort(iftrue=( &hasheader=0 )
  ,mac=&sysmacroname
  ,msg=%str(No header row in &inref)
)

/* get the variables in the CSV */
data _data_;
  infile &inref;
  input;
  length name $32;
  do i=1 to countc(_infile_,',')+1;
    name=upcase(scan(_infile_,i,','));
    output;
  end;
  stop;
run;
%local csv_vars;%let csv_vars=&syslast;

/* get the variables in the dataset */
proc contents noprint data=&baseds
  out=_data_ (keep=name type length format: informat);
run;
%local base_vars; %let base_vars=&syslast;

proc sql undo_policy=none;
create table &csv_vars as
  select a.*
    ,b.type
    ,b.length
    ,b.format
    ,b.formatd
    ,b.formatl
    ,b.informat
  from &csv_vars a
  left join &base_vars b
  on a.name=upcase(b.name)
  order by i;

/* prepare the input statement */
%local instat dropvars;
data _null_;
  set &syslast end=last;
  length in dropvars $32767;
  retain in dropvars;
  if missing(type) then do;
    informat='$1.';
    dropvars=catx(' ',dropvars,name);
  end;
  else if missing(informat) then do;
    if type=1 then informat='best.';
    else informat=cats('$',length,'.');
  end;
  else informat=cats(informat,'.');
  in=catx(' ',in,name,':',informat);
  if last then do;
    call symputx('instat',in,'l');
    call symputx('dropvars',dropvars,'l');
  end;
run;

/* import the CSV */
data &outds
  %if %upcase(&view)=YES %then %do;
    /view=&outds
  %end;
  ;
  infile &inref dsd firstobs=2;
  input &instat;
  %if %length(&dropvars)>0 %then %do;
    drop &dropvars;
  %end;
run;

%mend mp_csv2ds;/**
  @file mp_deleteconstraints.sas
  @brief Delete constraionts
  @details Takes the output from mp_getconstraints.sas as input

        proc sql;
        create table work.example(
          TX_FROM float format=datetime19.,
          DD_TYPE char(16),
          DD_SOURCE char(2048),
          DD_SHORTDESC char(256),
          constraint pk primary key(tx_from, dd_type,dd_source),
          constraint unq unique(tx_from, dd_type),
          constraint nnn not null(DD_SHORTDESC)
        );

      %mp_getconstraints(lib=work,ds=example,outds=work.constraints)
      %mp_deleteconstraints(inds=work.constraints,outds=dropped,execute=YES)

  @param inds= The input table containing the constraint info
  @param outds= a table containing the drop statements (drop_statement column)
  @param execute= `YES|NO` - default is NO. To actually drop, use YES.


  @version 9.2
  @author Allan Bowe

**/

%macro mp_deleteconstraints(inds=mp_getconstraints
  ,outds=mp_deleteconstraints
  ,execute=NO
)/*/STORE SOURCE*/;

proc sort data=&inds out=&outds;
  by libref table_name constraint_name;
run;

data &outds;
  set &outds;
  by libref table_name constraint_name;
  length drop_statement $500;
  if _n_=1 and "&execute"="YES" then call execute('proc sql;');
  if first.constraint_name then do;
    drop_statement=catx(" ","alter table",libref,".",table_name
      ,"drop constraint",constraint_name,";");
    output;
    if "&execute"="YES" then call execute(drop_statement);
  end;
run;

%mend mp_deleteconstraints;/**
  @file
  @brief A macro to delete a directory
  @details Will delete all folder content (including subfolder content) and
    finally, the folder itself.

  Usage:

      %let rootdir=%sysfunc(pathname(work))/demo;
      %mf_mkdir(&rootdir)
      %mf_mkdir(&rootdir/subdir)
      %mf_mkdir(&rootdir/subdir/subsubdir)
      data "&rootdir/subdir/example.sas7bdat";
      run;

      %mp_deletefolder(&rootdir)

  @param path Unquoted path to the folder to delete.

  <h4> SAS Macros </h4>
  @li mf_getuniquename.sas
  @li mf_isdir.sas
  @li mp_dirlist.sas

  <h4> Related Macros </h4>
  @li mp_deletefolder.test.sas

**/

%macro mp_deletefolder(folder);
  /* proceed if valid directory */
  %if %mf_isdir(&folder)=1 %then %do;

    /* prep temp table */
    %local tempds;
    %let tempds=%mf_getuniquename();

    /* recursive directory listing */
    %mp_dirlist(path=&folder,outds=work.&tempds, maxdepth=MAX)

    /* sort descending level so can delete folder contents before folders */
    proc sort data=work.&tempds;
      by descending level;
    run;

    /* ensure top level folder is removed at the end */
    proc sql;
    insert into work.&tempds set filepath="&folder";

    /* delete everything */
    data _null_;
      set work.&tempds end=last;
      length fref $8;
      rc=filename(fref,filepath);
      rc=fdelete(fref);
      if rc then do;
        msg=sysmsg();
        put "&sysmacroname:" / rc= / msg= / filepath=;
      end;
      rc=filename(fref);
    run;

    /* tidy up */
    proc sql;
    drop table work.&tempds;

  %end;
  %else %put &sysmacroname: &folder: is not a valid / accessible folder. ;
%mend mp_deletefolder;/**
  @file
  @brief Returns all files and subdirectories within a specified parent
  @details When used with getattrs=NO, is not OS specific (uses dopen / dread).

  Credit for the rename approach:
  https://communities.sas.com/t5/SAS-Programming/SAS-Function-to-convert-string-to-Legal-SAS-Name/m-p/27375/highlight/true#M5003


  usage:

      %mp_dirlist(path=/some/location, outds=myTable, maxdepth=MAX)

      %mp_dirlist(outds=cwdfileprops, getattrs=YES)

      %mp_dirlist(fref=MYFREF)

  @warning In a Unix environment, the existence of a named pipe will cause this
  macro to hang.  Therefore this tool should be used with caution in a SAS 9 web
  application, as it can use up all available multibridge sessions if requests
  are resubmitted.
  If anyone finds a way to positively identify a named pipe using SAS (without
  X CMD) do please raise an issue!


  @param [in] path= for which to return contents
  @param [in] fref= Provide a DISK engine fileref as an alternative to PATH
  @param [in] maxdepth= (0) Set to a positive integer to indicate the level of
    subdirectory scan recursion - eg 3, to go `./3/levels/deep`.  For unlimited
    recursion, set to MAX.
  @param [out] outds= the output dataset to create
  @param [out] getattrs= (NO)  If getattrs=YES then the doptname / foptname
    functions are used to scan all properties - any characters that are not
    valid in a SAS name (v7) are simply stripped, and the table is transposed
    so theat each property is a column and there is one file per row.  An
    attempt is made to get all properties whether a file or folder, but some
    files/folders cannot be accessed, and so not all properties can / will be
    populated.


  @returns outds contains the following variables:
    - directory (containing folder)
    - file_or_folder (file / folder)
    - filepath (path/to/file.name)
    - filename (just the file name)
    - ext (.extension)
    - msg (system message if any issues)
    - level (depth of folder)
    - OS SPECIFIC variables, if <code>getattrs=</code> is used.

  <h4> SAS Macros </h4>
  @li mp_dropmembers.sas

  <h4> Related Macros </h4>
  @li mp_dirlist.test.sas

  @version 9.2
  @author Allan Bowe
**/

%macro mp_dirlist(path=%sysfunc(pathname(work))
    , fref=0
    , outds=work.mp_dirlist
    , getattrs=NO
    , maxdepth=0
    , level=0 /* The level of recursion to perform.  For internal use only. */
)/*/STORE SOURCE*/;
%let getattrs=%upcase(&getattrs)XX;

/* temp table */
%local out_ds;
data;run;
%let out_ds=%str(&syslast);

/* drop main (top) table if it exists */
%if &level=0 %then %do;
  %mp_dropmembers(%scan(&outds,-1,.), libref=WORK)
%end;

data &out_ds(compress=no
    keep=file_or_folder filepath filename ext msg directory level
  );
  length directory filepath $500 fref fref2 $8 file_or_folder $6 filename $80
    ext $20 msg $200;
  retain level &level;
  %if &fref=0 %then %do;
    rc = filename(fref, "&path");
  %end;
  %else %do;
    fref="&fref";
    rc=0;
  %end;
  if rc = 0 then do;
    did = dopen(fref);
    directory=dinfo(did,'Directory');
    if did=0 then do;
      putlog "NOTE: This directory is empty - " directory;
      msg=sysmsg();
      put _all_;
      stop;
    end;
    rc = filename(fref);
  end;
  else do;
    msg=sysmsg();
    put _all_;
    stop;
  end;
  dnum = dnum(did);
  do i = 1 to dnum;
    filename = dread(did, i);
    filepath=cats(directory,'/',filename);
    rc = filename(fref2,filepath);
    midd=dopen(fref2);
    dmsg=sysmsg();
    if did > 0 then file_or_folder='folder';
    rc=dclose(midd);
    midf=fopen(fref2);
    fmsg=sysmsg();
    if midf > 0 then file_or_folder='file';
    rc=fclose(midf);

    if index(fmsg,'File is in use') or index(dmsg,'is not a directory')
      then file_or_folder='file';
    else if index(fmsg,'Insufficient authorization') then file_or_folder='file';
    else if file_or_folder='' then file_or_folder='locked';

    if file_or_folder='file' then do;
      ext = prxchange('s/.*\.{1,1}(.*)/$1/', 1, filename);
      if filename = ext then ext = ' ';
    end;
    else do;
      ext='';
      file_or_folder='folder';
    end;
    output;
  end;
  rc = dclose(did);
  stop;
run;

%if %substr(&getattrs,1,1)=Y %then %do;
  data &out_ds;
    set &out_ds;
    length infoname infoval $60 fref $8;
    rc=filename(fref,filepath);
    drop rc infoname fid i close fref;
    if file_or_folder='file' then do;
      fid=fopen(fref);
      if fid le 0 then do;
        msg=sysmsg();
        putlog "Could not open file:" filepath fid= ;
        sasname='_MCNOTVALID_';
        output;
      end;
      else do i=1 to foptnum(fid);
        infoname=foptname(fid,i);
        infoval=finfo(fid,infoname);
        sasname=compress(infoname, '_', 'adik');
        if anydigit(sasname)=1 then sasname=substr(sasname,anyalpha(sasname));
        if upcase(sasname) ne 'FILENAME' then output;
      end;
      close=fclose(fid);
    end;
    else do;
      fid=dopen(fref);
      if fid le 0 then do;
        msg=sysmsg();
        putlog "Could not open folder:" filepath fid= ;
        sasname='_MCNOTVALID_';
        output;
      end;
      else do i=1 to doptnum(fid);
        infoname=doptname(fid,i);
        infoval=dinfo(fid,infoname);
        sasname=compress(infoname, '_', 'adik');
        if anydigit(sasname)=1 then sasname=substr(sasname,anyalpha(sasname));
        if upcase(sasname) ne 'FILENAME' then output;
      end;
      close=dclose(fid);
    end;
  run;
  proc sort;
    by filepath sasname;
  proc transpose data=&out_ds out=&out_ds(drop=_:);
    id sasname;
    var infoval;
    by filepath file_or_folder filename ext ;
  run;
%end;

data &out_ds;
  set &out_ds(where=(filepath ne ''));
run;

/* update main table */
proc append base=&outds data=&out_ds;
run;

/* recursive call */
%if &maxdepth>&level or &maxdepth=MAX %then %do;
  data _null_;
    set &out_ds;
    where file_or_folder='folder';
    length code $10000;
    code=cats('%nrstr(%mp_dirlist(path=',filepath,",outds=&outds"
      ,",getattrs=&getattrs,level=%eval(&level+1),maxdepth=&maxdepth))");
    put code=;
    call execute(code);
  run;
%end;

/* tidy up */
proc sql;
drop table &out_ds;

%mend mp_dirlist;/**
  @file
  @brief Creates a dataset containing distinct _formatted_ values
  @details If no format is supplied, then the original value is used instead.
    There is also a dependency on other macros within the Macro Core library.
    Usage:

        %mp_distinctfmtvalues(libds=sashelp.class,var=age,outvar=age,outds=test)

  @param libds input dataset
  @param var variable to get distinct values for
  @param outvar variable to create.  Default:  `formatted_value`
  @param outds dataset to create.  Default:  work.mp_distinctfmtvalues
  @param varlen length of variable to create (default 200)

  @version 9.2
  @author Allan Bowe

**/

%macro mp_distinctfmtvalues(
    libds=
    ,var=
    ,outvar=formatted_value
    ,outds=work.mp_distinctfmtvalues
    ,varlen=2000
)/*/STORE SOURCE*/;

  %local fmt vtype;
  %let fmt=%mf_getvarformat(&libds,&var);
  %let vtype=%mf_getvartype(&libds,&var);

  proc sql;
  create table &outds as
    select distinct
    %if &vtype=C & %trim(&fmt)=%str() %then %do;
      &var
    %end;
    %else %if &vtype=C %then %do;
      put(&var,&fmt)
    %end;
    %else %if %trim(&fmt)=%str() %then %do;
        put(&var,32.)
    %end;
    %else %do;
      put(&var,&fmt)
    %end;
        as &outvar length=&varlen
    from &libds;
%mend mp_distinctfmtvalues;/**
  @file
  @brief Drops tables / views (if they exist) without warnings in the log
  @details Useful for dropping tables when you're not sure they exist, or if
  you are not sure whether they are a dataset or view.  Also efficient for
  dropping multiple tables / views.

  Example usage:

      proc sql;
      create table data1 as select * from sashelp.class;
      create view view2 as select * from sashelp.class;
      %mp_dropmembers(data1 view2, libref=WORK)


  <h4> SAS Macros </h4>
  @li mf_isblank.sas


  @param [in] list space separated list of datasets / views, WITHOUT libref
  @param [in] libref= (WORK) Note - you can only drop from one library at a time
  @param [in] iftrue= (1=1) Conditionally drop tables, eg if &debug=N

  @version 9.2
  @author Allan Bowe

**/

%macro mp_dropmembers(
    list /* space separated list of datasets / views */
    ,libref=WORK  /* can only drop from a single library at a time */
    ,iftrue=%str(1=1)
)/*/STORE SOURCE*/;

  %if not(%eval(%unquote(&iftrue))) %then %return;

  %if %mf_isblank(&list) %then %do;
    %put NOTE: nothing to drop!;
    %return;
  %end;

  proc datasets lib=&libref nolist;
    delete &list;
    delete &list /mtype=view;
  run;
%mend mp_dropmembers;/**
  @file
  @brief Create a CARDS file from a SAS dataset.
  @details Uses dataset attributes to convert all data into datalines.
    Running the generated file will rebuild the original dataset.  Includes
    support for large decimals, binary data, PROCESSED_DTTM columns, and
    alternative encoding.  If the input dataset is empty, the cards file will
    still be created.

    Additional support to generate a random sample and max rows.

  Usage:

      %mp_ds2cards(base_ds=sashelp.class
        , tgt_ds=work.class
        , cards_file= "C:\temp\class.sas"
        , showlog=NO
        , maxobs=5
      )

  TODO:
    - labelling the dataset
    - explicity setting a unix LF
    - constraints / indexes etc

  @param [in] base_ds= Should be two level - eg work.blah.  This is the table
                  that is converted to a cards file.
  @param [in] tgt_ds= Table that the generated cards file would create.
    Optional - if omitted, will be same as BASE_DS.
  @param [out] cards_file= ("%sysfunc(pathname(work))/cardgen.sas") Location in
    which to write the (.sas) cards file
  @param [in] maxobs= (max) To limit output to the first <code>maxobs</code>
    observations, enter an integer here.
  @param [in] random_sample= (NO) Set to YES to generate a random sample of
    data.  Can be quite slow.
  @param [in] showlog= (YES) Whether to show generated cards file in the SAS
    log.  Valid values:
    @li YES
    @li NO
  @param [in] outencoding= Provide encoding value for file statement (eg utf-8)
  @param [in] append= (NO) If NO then will rebuild the cards file if it already
    exists, otherwise will append to it.  Used by the mp_lib2cards.sas macro.

  <h4> Related Macros </h4>
  @li mp_lib2cards.sas
  @li mp_ds2inserts.sas
  @li mp_mdtablewrite.sas

  @version 9.2
  @author Allan Bowe
**/

%macro mp_ds2cards(base_ds=, tgt_ds=
    ,cards_file="%sysfunc(pathname(work))/cardgen.sas"
    ,maxobs=max
    ,random_sample=NO
    ,showlog=YES
    ,outencoding=
    ,append=NO
)/*/STORE SOURCE*/;
%local i setds nvars;

%if not %sysfunc(exist(&base_ds)) %then %do;
  %put %str(WARN)ING:  &base_ds does not exist;
  %return;
%end;

%if %index(&base_ds,.)=0 %then %let base_ds=WORK.&base_ds;
%if (&tgt_ds = ) %then %let tgt_ds=&base_ds;
%if %index(&tgt_ds,.)=0 %then %let tgt_ds=WORK.%scan(&base_ds,2,.);
%if ("&outencoding" ne "") %then %let outencoding=encoding="&outencoding";
%if ("&append" = "" or "&append" = "NO") %then %let append=;
%else %let append=mod;

/* get varcount */
%let nvars=0;
proc sql noprint;
select count(*) into: nvars from dictionary.columns
  where upcase(libname)="%scan(%upcase(&base_ds),1)"
    and upcase(memname)="%scan(%upcase(&base_ds),2)";
%if &nvars=0 %then %do;
  %put %str(WARN)ING: Dataset &base_ds has no variables, will not be converted.;
  %return;
%end;

/* get indexes */
proc sort
  data=sashelp.vindex(
    where=(upcase(libname)="%scan(%upcase(&base_ds),1)"
      and upcase(memname)="%scan(%upcase(&base_ds),2)")
    )
  out=_data_;
  by indxname indxpos;
run;

%local indexes;
data _null_;
  set &syslast end=last;
  if _n_=1 then call symputx('indexes','(index=(','l');
  by indxname indxpos;
  length vars $32767 nom uni $8;
  retain vars;
  if first.indxname then do;
    idxcnt+1;
    nom='';
    uni='';
    vars=name;
  end;
  else vars=catx(' ',vars,name);
  if last.indxname then do;
    if nomiss='yes' then nom='/nomiss';
    if unique='yes' then uni='/unique';
    call symputx('indexes'
      ,catx(' ',symget('indexes'),indxname,'=(',vars,')',nom,uni)
      ,'l');
  end;
  if last then call symputx('indexes',cats(symget('indexes'),'))'),'l');
run;


data;run;
%let setds=&syslast;
proc sql
%if %datatyp(&maxobs)=NUMERIC %then %do;
  outobs=&maxobs;
%end;
  ;
  create table &setds as select * from &base_ds
%if &random_sample=YES %then %do;
  order by ranuni(42)
%end;
  ;
reset outobs=max;
create table datalines1 as
  select name,type,length,varnum,format,label from dictionary.columns
  where upcase(libname)="%upcase(%scan(&base_ds,1))"
    and upcase(memname)="%upcase(%scan(&base_ds,2))";

/**
  Due to long decimals cannot use best. format
  So - use bestd. format and then use character functions to strip trailing
    zeros, if NOT an integer!!
  resolved code = ifc(int(VARIABLE)=VARIABLE
    ,put(VARIABLE,best32.)
    ,substrn(put(VARIABLE,bestd32.),1
    ,findc(put(VARIABLE,bestd32.),'0','TBK')));
**/

data datalines_2;
  format dataline $32000.;
  set datalines1 (where=(upcase(name) not in
    ('PROCESSED_DTTM','VALID_FROM_DTTM','VALID_TO_DTTM')));
  if type='num' then dataline=
    cats('ifc(int(',name,')=',name,'
      ,put(',name,',best32.-l)
      ,substrn(put(',name,',bestd32.-l),1
      ,findc(put(',name,',bestd32.-l),"0","TBK")))');
  /**
    * binary data must be converted, to store in text format.  It is identified
    * by the presence of the $HEX keyword in the format.
    */
  else if upcase(format)=:'$HEX' then
    dataline=cats('put(trim(',name,'),',format,')');
  /**
    * There is no easy way to store line breaks in a cards file.
    * To discuss this, use: https://github.com/sasjs/core/issues/80
    * Removing all nonprintables with kw (keep writeable)
    */
  else dataline=cats('compress(',name,', ,"kw")');
run;

proc sql noprint;
select dataline into: datalines separated by ',' from datalines_2;

%local
  process_dttm_flg
  valid_from_dttm_flg
  valid_to_dttm_flg
;
%let process_dttm_flg = N;
%let valid_from_dttm_flg = N;
%let valid_to_dttm_flg = N;
data _null_;
  set datalines1 ;
/* build attrib statement */
  if type='char' then type2='$';
  if strip(format) ne '' then format2=cats('format=',format);
  if strip(label) ne '' then label2=cats('label=',quote(trim(label)));
  str1=catx(' ',(put(name,$33.)||'length=')
        ,put(cats(type2,length),$7.)||format2,label2);


/* Build input statement */
  if upcase(format)=:'$HEX' then type3=':'!!format;
  else if type='char' then type3=':$char.';
  str2=put(name,$33.)||type3;


  if(upcase(name) = "PROCESSED_DTTM") then
    call symputx("process_dttm_flg", "Y", "L");
  if(upcase(name) = "VALID_FROM_DTTM") then
    call symputx("valid_from_dttm_flg", "Y", "L");
  if(upcase(name) = "VALID_TO_DTTM") then
    call symputx("valid_to_dttm_flg", "Y", "L");


  call symputx(cats("attrib_stmt_", put(_N_, 8.)), str1, "L");
  call symputx(cats("input_stmt_", put(_N_, 8.))
    , ifc(upcase(name) not in
      ('PROCESSED_DTTM','VALID_FROM_DTTM','VALID_TO_DTTM'), str2, ""), "L");
run;

data _null_;
  file &cards_file. &outencoding lrecl=32767 termstr=nl &append;
  length __attrib $32767;
  if _n_=1 then do;
    put '/**';
    put '  @file';
    put "  @brief Datalines for %upcase(%scan(&base_ds,2)) dataset";
    put "  @details Generated by %nrstr(%%)mp_ds2cards()";
    put "  Available on github.com/sasjs/core";
    put '**/';
    put "data &tgt_ds &indexes;";
    put "attrib ";
    %do i = 1 %to &nvars;
      __attrib=symget("attrib_stmt_&i");
      put __attrib;
    %end;
    put ";";

    %if &process_dttm_flg. eq Y %then %do;
      put 'retain PROCESSED_DTTM %sysfunc(datetime());';
    %end;
    %if &valid_from_dttm_flg. eq Y %then %do;
      put 'retain VALID_FROM_DTTM &low_date;';
    %end;
    %if &valid_to_dttm_flg. eq Y %then %do;
      put 'retain VALID_TO_DTTM &high_date;';
    %end;
    if __nobs=0 then do;
      put 'call missing(of _all_);/* avoid uninitialised notes */';
      put 'stop;';
      put 'run;';
    end;
    else do;
      put "infile cards dsd;";
      put "input ";
      %do i = 1 %to &nvars.;
        %if(%length(&&input_stmt_&i..)) %then
          put "  &&input_stmt_&i..";
        ;
      %end;
      put ";";
      put "datalines4;";
    end;
  end;
  set &setds end=__lastobs nobs=__nobs;
/* remove all formats for write purposes - some have long underlying decimals */
  format _numeric_ best30.29;
  length __dataline $32767;
  __dataline=catq('cqtmb',&datalines);
  put __dataline;
  if __lastobs then do;
    put ';;;;';
    put 'run;';
    stop;
  end;
run;
proc sql;
  drop table &setds;
quit;

%if &showlog=YES %then %do;
  data _null_;
    infile &cards_file lrecl=32767;
    input;
    put _infile_;
  run;
%end;

%put NOTE: CARDS FILE SAVED IN:;
%put NOTE-;%put NOTE-;
%put NOTE- %sysfunc(dequote(&cards_file.));
%put NOTE-;%put NOTE-;
%mend mp_ds2cards;/**
  @file
  @brief Export a dataset to a CSV file
  @details Export to a file or a fileref
  Usage:

      %mp_ds2csv(sashelp.class,outref="%sysfunc(pathname(work))/file.csv")

  @param ds The dataset to be exported
  @param outfile= The output filename - should be quoted.
  @param outref= The output fileref (takes precedence if provided)
  @param outencoding= The output encoding to use (unquoted)

  @version 9.2
  @author Allan Bowe (credit mjsq)
**/

%macro mp_ds2csv(ds, outref=0, outfile=, outencoding=0
)/*/STORE SOURCE*/;

%if not %sysfunc(exist(&ds)) %then %do;
  %put %str(WARN)ING:  &ds does not exist;
  %return;
%end;

%if %index(&ds,.)=0 %then %let ds=WORK.&ds;

%if &outencoding=0 %then %let outencoding=;
%else %let outencoding=encoding="&outencoding";

%local outloc;
%if &outref=0 %then %let outloc=&outfile;
%else %let outloc=&outref;

/* credit to mjsq - https://stackoverflow.com/a/55642267 */

/* first get headers */
data _null_;
  file &outloc dlm=',' dsd &outencoding lrecl=32767;
  length header $ 2000;
  dsid=open("&ds.","i");
  num=attrn(dsid,"nvars");
  do i=1 to num;
    header = trim(left(coalescec(varlabel(dsid,i),varname(dsid,i))));
    put header @;
  end;
  rc=close(dsid);
run;

/* next, export data */
data _null_;
  set &ds.;
  file &outloc mod dlm=',' dsd &outencoding lrecl=32767;
  put (_all_) (+0);
run;


%mend mp_ds2csv;/**
  @file
  @brief Converts every value in a dataset to formatted value
  @details Converts every value to it's formatted value.  All variables will
  become character, and will be in the same order as the original dataset.

  Lengths will be adjusted according to the format lengths, where applicable.

  Usage:

      %mp_ds2fmtds(sashelp.cars,work.cars)
      %mp_ds2fmtds(sashelp.vallopt,vw_vallopt)

  @param [in] libds The library.dataset to be converted
  @param [out] outds The dataset to create.

  <h4> SAS Macros </h4>
  @li mf_existds.sas

  <h4> Related Macros <h4>
  @li mp_jsonout.sas

  @version 9.2
  @author Allan Bowe
**/

%macro mp_ds2fmtds(libds, outds
)/*/STORE SOURCE*/;

/* validations */

%if not %mf_existds(libds=&libds) %then %do;
  %put %str(WARN)ING:  &libds does not exist as either a VIEW or DATASET;
  %return;
%end;
%if %index(&libds,.)=0 %then %let libds=WORK.&libds;

/* grab metadata */
proc contents noprint data=&libds
  out=_data_(keep=name type length format formatl formatd varnum);
run;
proc sort;
  by varnum;
run;

/* prepare formats and varnames */
data _null_;
  set &syslast end=last;
  name=upcase(name);
  /* fix formats */
  if type=2 or type=6 then do;
    length fmt $49.;
    if format='' then fmt=cats('$',length,'.');
    else if formatl=0 then fmt=cats(format,'.');
    else fmt=cats(format,formatl,'.');
    newlen=max(formatl,length);
  end;
  else do;
    if format='' then fmt='best.';
    else if formatl=0 then fmt=cats(format,'.');
    else if formatd=0 then fmt=cats(format,formatl,'.');
    else fmt=cats(format,formatl,'.',formatd);
    /* needs to be wide, for datetimes etc */
    newlen=max(length,formatl,24);
  end;
  /* 32 char unique name */
  newname='sasjs'!!substr(cats(put(md5(name),$hex32.)),1,27);

  call symputx(cats('name',_n_),name,'l');
  call symputx(cats('newname',_n_),newname,'l');
  call symputx(cats('len',_n_),newlen,'l');
  call symputx(cats('fmt',_n_),fmt,'l');
  call symputx(cats('type',_n_),type,'l');
  if last then call symputx('nobs',_n_,'l');
run;

/* clean up */
proc sql;
drop table &syslast;

%if &nobs=0 %then %do;
  %put Dataset &libds has no columns!
  data &outds;
    set &libds;
  run;
  %return;
%end;

data &outds;
  /* rename on entry */
  set &libds(rename=(
%local i;
%do i=1 %to &nobs;
  &&name&i=&&newname&i
%end;
  ));
%do i=1 %to &nobs;
  length &&name&i $&&len&i;
  &&name&i=left(put(&&newname&i,&&fmt&i));
  drop &&newname&i;
%end;
  if _error_ then call symputx('syscc',1012);
run;

%mend mp_ds2fmtds;/**
  @file
  @brief Export a dataset to SQL insert statements
  @details Converts dataset values to SQL insert statements for use across
  multiple database types.

  Usage:

      %mp_ds2inserts(sashelp.class,outref=myref,outds=class)
      data class;
        set sashelp.class;
        stop;
      proc sql;
      %inc myref;

  @param [in] ds The dataset to be exported
  @param [in] maxobs= (max) The max number of inserts to create
  @param [out] outref= (0) The output fileref.  If it does not exist, it is
    created. If it does exist, new records are APPENDED.
  @param [out] schema= (0) The library (or schema) in which the target table is
    located.  If not provided, is ignored.
  @param [out] outds= (0) The output table to load.  If not provided, will
    default to the table in the &ds parameter.
  @param [in] flavour= (SAS) The SQL flavour to be applied to the output. Valid
    options:
    @li SAS (default) - suitable for regular proc sql
    @li PGSQL - Used for Postgres databases
  @param [in] applydttm= (YES) If YES, any columns using datetime formats will
    be converted to native DB datetime literals

  <h4> SAS Macros </h4>
  @li mf_existfileref.sas
  @li mf_getvarcount.sas
  @li mf_getvarformat.sas
  @li mf_getvarlist.sas
  @li mf_getvartype.sas

  @version 9.2
  @author Allan Bowe (credit mjsq)
**/

%macro mp_ds2inserts(ds, outref=0,schema=0,outds=0,flavour=SAS,maxobs=max
  ,applydttm=YES
)/*/STORE SOURCE*/;

%if not %sysfunc(exist(&ds)) %then %do;
  %put %str(WAR)NING:  &ds does not exist;
  %return;
%end;

%if not %sysfunc(exist(&ds)) %then %do;
  %put %str(WAR)NING:  &ds does not exist;
  %return;
%end;

%if %index(&ds,.)=0 %then %let ds=WORK.&ds;

%let flavour=%upcase(&flavour);
%if &flavour ne SAS and &flavour ne PGSQL %then %do;
  %put %str(WAR)NING:  &flavour is not supported;
  %return;
%end;

%if &outref=0 %then %do;
  %put %str(WAR)NING:  Please provide a fileref;
  %return;
%end;
%if %mf_existfileref(&outref)=0 %then %do;
  filename &outref temp lrecl=66000;
%end;

%if &schema=0 %then %let schema=;
%else %let schema=&schema..;

%if &outds=0 %then %let outds=%scan(&ds,2,.);

%local nobs;
proc sql noprint;
select count(*) into: nobs TRIMMED from &ds;
%if &nobs=0 %then %do;
  data _null_;
    file &outref mod;
    put "/* No rows found in &ds */";
  run;
%end;

%local vars;
%let vars=%mf_getvarcount(&ds);
%if &vars=0 %then %do;
  data _null_;
    file &outref mod;
    put "/* No columns found in &schema.&ds */";
  run;
  %return;
%end;
%else %if &vars>1600 and &flavour=PGSQL %then %do;
  data _null_;
    file &fref mod;
    put "/* &schema.&ds contains &vars vars */";
    put "/* Postgres cannot handle tables with over 1600 vars */";
    put "/* No inserts will be generated for this table */";
  run;
  %return;
%end;

%local varlist varlistcomma;
%let varlist=%mf_getvarlist(&ds);
%let varlistcomma=%mf_getvarlist(&ds,dlm=%str(,),quote=double);

/* next, export data */
data _null_;
  file &outref mod ;
  if _n_=1 then put "/* &schema.&outds (&nobs rows, &vars columns) */";
  set &ds;
  %if &maxobs ne max %then %do;
    if _n_>&maxobs then stop;
  %end;
  length _____str $32767;
  call missing(_____str);
  format _numeric_ best.;
  format _character_ ;
  %local i comma var vtype vfmt;
  %do i=1 %to %sysfunc(countw(&varlist));
    %let var=%scan(&varlist,&i);
    %let vtype=%mf_getvartype(&ds,&var);
    %let vfmt=%upcase(%mf_getvarformat(&ds,&var,force=1));
    %if &i=1 %then %do;
      %if &flavour=SAS %then %do;
        put "insert into &schema.&outds set ";
        put "  &var="@;
      %end;
      %else %if &flavour=PGSQL %then %do;
        _____str=cats(
          "INSERT INTO &schema.&outds ("
          ,symget('varlistcomma')
          ,") VALUES ("
        );
        put _____str;
        put "  "@;
      %end;
    %end;
    %else %do;
      %if &flavour=SAS %then %do;
        put "  ,&var="@;
      %end;
      %else %if &flavour=PGSQL %then %do;
        put "  ,"@;
      %end;
    %end;
    %if &vtype=N %then %do;
      %if &flavour=SAS %then %do;
        put &var;
      %end;
      %else %if &flavour=PGSQL %then %do;
        if missing(&var) then put 'NULL';
        %if &applydttm=YES and "%substr(&vfmt.xxxxxxxx,1,8)"="DATETIME"
        %then %do;
          else put "TIMESTAMP '" &var E8601DT25.6 "'";
        %end;
        %else %do;
          else put &var;
        %end;
      %end;
    %end;
    %else %do;
      _____str="'"!!trim(tranwrd(&var,"'","''"))!!"'";
      put _____str;
    %end;
  %end;
  %if &flavour=SAS %then %do;
    put ';';
  %end;
  %else %if &flavour=PGSQL %then %do;
    put ');';
  %end;

  if _n_=&nobs then put /;
run;

%mend mp_ds2inserts;/**
  @file
  @brief Create a Markdown Table from a dataset
  @details A markdown table is a simple table representation for use in
  documents written in markdown format.

  An online generator is available here:
  https://www.tablesgenerator.com/markdown_tables

  This structure is also used by the Macro Core library for documenting input/
  output datasets, as well as the sasjs/cli tool for documenting inputs/outputs
  for web services.

  We take the standard definition one step further by embedding the informat
  in the table header row, like so:

      |var1:$32|var2:best.|var3:date9.|
      |---|---|---|
      |some text|42|01JAN1960|
      |blah|1|31DEC1999|

  Which resolves to:

  |var1:$32|var2:best.|var3:date9.|
  |---|---|---|
  |some text|42|01JAN1960|
  |blah|1|31DEC1999|


  Usage:

      %mp_ds2md(sashelp.class)

  @param [in] libds the library / dataset to create or read from.
  @param [out] outref= (mdtable) Fileref to contain the markdown
  @param [out] showlog= (YES) Set to NO to avoid printing markdown to the log

  <h4> SAS Macros </h4>
  @li mf_getvarlist.sas
  @li mf_getvarformat.sas

  @version 9.3
  @author Allan Bowe
**/

%macro mp_ds2md(
  libds,
  outref=mdtable,
  showlog=YES
)/*/STORE SOURCE*/;

/* check fileref is assigned */
%if %sysfunc(fileref(&outref)) > 0 %then %do;
  filename &outref temp;
%end;

%local vars;
%let vars=%upcase(%mf_getvarlist(&libds));

/* create the header row */
data _null_;
  file &outref;
  length line $32767;
  call missing(line);
  put '|'
%local i var fmt;
%do i=1 %to %sysfunc(countw(&vars));
  %let var=%scan(&vars,&i);
  %let fmt=%lowcase(%mf_getvarformat(&libds,&var,force=1));
  "&var:&fmt|"
%end;
  ;
  put '|'
%do i=1 %to %sysfunc(countw(&vars));
  "---|"
%end;
  ;
run;

/* write out the data */
data _null_;
  file &outref mod dlm='|' lrecl=32767;
  set &libds ;
  length line $32767;
  line='|`'!!cats(%mf_getvarlist(&libds,dlm=%str(%)!!' `|`'!!cats%()))!!' `|';
  put line;
run;

%if %upcase(&showlog)=YES %then %do;
  options ps=max;
  data _null_;
    infile &outref;
    input;
    putlog _infile_;
  run;
%end;

%mend mp_ds2md;/**
  @file
  @brief Checks an input filter table for validity
  @details Performs checks on the input table to ensure it arrives in the
  correct format.  This is necessary to prevent code injection.  Will update
  SYSCC to 1008 if bad records are found, and call mp_abort.sas for a
  graceful service exit (configurable).

  Used for dynamic filtering in [Data Controller for SAS&reg;](https://datacontroller.io).

  Usage:

      %mp_filtercheck(work.filter,targetds=sashelp.class,outds=work.badrecords)

  The input table should have the following format:

  |GROUP_LOGIC:$3|SUBGROUP_LOGIC:$3|SUBGROUP_ID:8.|VARIABLE_NM:$32|OPERATOR_NM:$10|RAW_VALUE:$4000|
  |---|---|---|---|---|---|
  |AND|AND|1|AGE|=|12|
  |AND|AND|1|SEX|<=|'M'|
  |AND|OR|2|Name|NOT IN|('Jane','Alfred')|
  |AND|OR|2|Weight|>=|7|

  Rules applied:

  @li GROUP_LOGIC - only AND/OR
  @li SUBGROUP_LOGIC - only AND/OR
  @li SUBGROUP_ID - only integers
  @li VARIABLE_NM - must be in the target table
  @li OPERATOR_NM - only =/>/</<=/>=/BETWEEN/IN/NOT IN/NE/CONTAINS
  @li RAW_VALUE - no unquoted values except integers, commas and spaces.

  @returns The &outds table containing any bad rows, plus a REASON_CD column.

  @param [in] inds The table to be checked, with the format above
  @param [in] targetds= The target dataset against which to verify VARIABLE_NM.
    This must be available (ie, the library must be assigned).
  @param [out] abort= (YES) If YES will call mp_abort.sas on any exceptions
  @param [out] outds= The output table, which is a copy of the &inds. table
    plus a REASON_CD column, containing only bad records.  If bad records found,
    the SYSCC value will be set to 1008 (general data problem).  Downstream
    processes should check this table (and return code) before continuing.

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getuniquefileref.sas
  @li mf_getvarlist.sas
  @li mf_getvartype.sas
  @li mp_filtergenerate.sas
  @li mp_filtervalidate.sas

  <h4> Related Macros </h4>
  @li mp_filtergenerate.sas
  @li mp_filtervalidate.sas

  @version 9.3
  @author Allan Bowe

  @todo Support date / hex / name literals and exponents in RAW_VALUE field
**/

%macro mp_filtercheck(inds,targetds=,outds=work.badrecords,abort=YES);

%mp_abort(iftrue= (&syscc ne 0)
  ,mac=&sysmacroname
  ,msg=%str(syscc=&syscc - on macro entry)
)

/* Validate input column */
%local vtype;
%let vtype=%mf_getvartype(&inds,RAW_VALUE);
%mp_abort(iftrue=(&abort=YES and &vtype ne C),
  mac=&sysmacroname,
  msg=%str(%str(ERR)OR: RAW_VALUE must be character)
)
%if &vtype ne C %then %do;
  %put &sysmacroname: RAW_VALUE must be character;
  %let syscc=42;
  %return;
%end;


/**
  * Sanitise the values based on valid value lists, then strip out
  * quotes, commas, periods and spaces.
  * Only numeric values should remain
  */
%local reason_cd nobs;
%let nobs=0;
data &outds;
  /*length GROUP_LOGIC SUBGROUP_LOGIC $3 SUBGROUP_ID 8 VARIABLE_NM $32
    OPERATOR_NM $10 RAW_VALUE $4000;*/
  set &inds;
  length reason_cd $4032;

  /* closed list checks */
  if GROUP_LOGIC not in ('AND','OR') then do;
    REASON_CD='GROUP_LOGIC should be AND/OR, not:'!!cats(GROUP_LOGIC);
    putlog REASON_CD= GROUP_LOGIC=;
    call symputx('reason_cd',reason_cd,'l');
    call symputx('nobs',_n_,'l');
    output;
  end;
  if SUBGROUP_LOGIC not in ('AND','OR') then do;
    REASON_CD='SUBGROUP_LOGIC should be AND/OR, not:'!!cats(SUBGROUP_LOGIC);
    putlog REASON_CD= SUBGROUP_LOGIC=;
    call symputx('reason_cd',reason_cd,'l');
    call symputx('nobs',_n_,'l');
    output;
  end;
  if mod(SUBGROUP_ID,1) ne 0 then do;
    REASON_CD='SUBGROUP_ID should be integer, not '!!left(subgroup_id);
    putlog REASON_CD= SUBGROUP_ID=;
    call symputx('reason_cd',reason_cd,'l');
    call symputx('nobs',_n_,'l');
    output;
  end;
  if upcase(VARIABLE_NM) not in
  (%upcase(%mf_getvarlist(&targetds,dlm=%str(,),quote=SINGLE)))
  then do;
    REASON_CD="Variable "!!cats(variable_nm)!!" not in &targetds";
    putlog REASON_CD= VARIABLE_NM=;
    call symputx('reason_cd',reason_cd,'l');
    call symputx('nobs',_n_,'l');
    output;
  end;
  if OPERATOR_NM not in
  ('=','>','<','<=','>=','BETWEEN','IN','NOT IN','NE','CONTAINS')
  then do;
    REASON_CD='Invalid OPERATOR_NM: '!!left(OPERATOR_NM);
    putlog REASON_CD= OPERATOR_NM=;
    call symputx('reason_cd',reason_cd,'l');
    call symputx('nobs',_n_,'l');
    output;
  end;

  /* special logic */
  if OPERATOR_NM='BETWEEN' then raw_value1=tranwrd(raw_value,' AND ','');
  else if OPERATOR_NM in ('IN','NOT IN') then do;
    if substr(raw_value,1,1) ne '('
    or substr(cats(reverse(raw_value)),1,1) ne ')'
    then do;
      REASON_CD='Missing start/end bracket in RAW_VALUE';
      putlog REASON_CD= OPERATOR_NM= raw_value= raw_value1= ;
      call symputx('reason_cd',reason_cd,'l');
      call symputx('nobs',_n_,'l');
      output;
    end;
    else raw_value1=substr(raw_value,2,max(length(raw_value)-2,0));
  end;
  else raw_value1=raw_value;

  /* remove nested literals eg '' */
  raw_value1=tranwrd(raw_value1,"''",'');

  /* now match string literals (always single quotes) */
  raw_value2=raw_value1;
  regex = prxparse("s/(\').*?(\')//");
  call prxchange(regex,-1,raw_value2);

  /* remove commas and periods*/
  raw_value3=compress(raw_value2,',.');

  /* output records that contain values other than digits and spaces */
  if notdigit(compress(raw_value3,' '))>0 then do;
    putlog raw_value3= $hex32.;
    REASON_CD=cats('Invalid RAW_VALUE:',raw_value);
    putlog REASON_CD= raw_value= raw_value1= raw_value2= raw_value3=;
    call symputx('reason_cd',reason_cd,'l');
    call symputx('nobs',_n_,'l');
    output;
  end;

run;


data _null_;
  set &outds end=last;
  putlog (_all_)(=);
run;

%mp_abort(iftrue=(&abort=YES and &nobs>0),
  mac=&sysmacroname,
  msg=%str(Data issue: %superq(reason_cd))
)

%if &nobs>0 %then %do;
  %let syscc=1008;
  %return;
%end;

/**
  * syntax checking passed but it does not mean the filter is valid
  * for that we can run a proc sql validate query
  */
%local fref1;
%let fref1=%mf_getuniquefileref();
%mp_filtergenerate(&inds,outref=&fref1)

/* this macro will also set syscc to 1008 if any issues found */
%mp_filtervalidate(&fref1,&targetds,outds=&outds,abort=&abort)

%mend mp_filtercheck;
/**
  @file
  @brief Generates a filter clause from an input table, to a fileref
  @details Uses the input table to generate an output filter clause.
  This feature is used to create dynamic dropdowns in [Data Controller for SAS&reg](
  https://datacontroller.io). The input table should be in the format below:

  |GROUP_LOGIC:$3|SUBGROUP_LOGIC:$3|SUBGROUP_ID:8.|VARIABLE_NM:$32|OPERATOR_NM:$10|RAW_VALUE:$4000|
  |---|---|---|---|---|---|
  |AND|AND|1|AGE|=|12|
  |AND|AND|1|SEX|<=|'M'|
  |AND|OR|2|Name|NOT IN|('Jane','Alfred')|
  |AND|OR|2|Weight|>=|7|

  Note - if the above table is received from an external client, the values
  should first be validated using the mp_filtercheck.sas macro to avoid risk
  of SQL injection.

  To generate the filter, run the following code:

      data work.filtertable;
        infile datalines4 dsd;
        input GROUP_LOGIC:$3. SUBGROUP_LOGIC:$3. SUBGROUP_ID:8. VARIABLE_NM:$32.
          OPERATOR_NM:$10. RAW_VALUE:$4000.;
      datalines4;
      AND,AND,1,AGE,=,12
      AND,AND,1,SEX,<=,"'M'"
      AND,OR,2,Name,NOT IN,"('Jane','Alfred')"
      AND,OR,2,Weight,>=,7
      ;;;;
      run;

      %mp_filtergenerate(work.filtertable,outref=myfilter)

      data _null_;
        infile myfilter;
        input;
        put _infile_;
      run;

  Will write the following query to the log:

  > (
  >     AGE = 12
  >   AND
  >     SEX <= 'M'
  > ) AND (
  >     Name NOT IN ('Jane','Alfred')
  >   OR
  >     Weight >= 7
  > )

  @param [in] inds The input table with query values
  @param [out] outref= The output fileref to contain the filter clause.  Will
    be created (or replaced).

  <h4> Related Macros </h4>
  @li mp_filtercheck.sas
  @li mp_filtervalidate.sas

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_nobs.sas

  @version 9.3
  @author Allan Bowe

**/

%macro mp_filtergenerate(inds,outref=filter);

%mp_abort(iftrue= (&syscc ne 0)
  ,mac=&sysmacroname
  ,msg=%str(syscc=&syscc - on macro entry)
)

filename &outref temp;

%if %mf_nobs(&inds)=0 %then %do;
  /* ensure we have a default filter */
  data _null_;
    file &outref;
    put '1=1';
  run;
%end;
%else %do;
  data _null_;
    file &outref lrecl=32800;
    set &inds end=last;
    by SUBGROUP_ID;
    if _n_=1 then put '((';
    else if first.SUBGROUP_ID then put +1 GROUP_LOGIC '(';
    else put +2 SUBGROUP_LOGIC;

    put +4 VARIABLE_NM OPERATOR_NM RAW_VALUE;

    if last.SUBGROUP_ID then put ')'@;
    if last then put ')';
  run;
%end;

%mend mp_filtergenerate;
/**
  @file
  @brief Checks & Stores an input filter table and returns the Filter Key
  @details Used to generate a FILTER_RK from an input query dataset.  This
  process requires several permanent tables (names are configurable).  The
  benefit of storing query values at backend is to enable stored 'views' of
  filtered tables at frontend (ie, when building [SAS-Powered Apps](
  https://sasapps.io)).  This macro is also used in [Data Controller for SAS](
  https://datacontroller.io).


  @param [in] libds= The target dataset to be filtered (lib should be assigned)
  @param [in] queryds= (WORK.FILTERQUERY) The temporary input query dataset to
    be validated.  Has the following format:
|GROUP_LOGIC:$3|SUBGROUP_LOGIC:$3|SUBGROUP_ID:8.|VARIABLE_NM:$32|OPERATOR_NM:$10|RAW_VALUE:$32767|
|---|---|---|---|---|---|
|AND|AND|1|SOME_BESTNUM|>|1|
|AND|AND|1|SOME_TIME|=|77333|
  @param [in] filter_summary= (PERM.FILTER_SUMMARY) Permanent table containing
    summary filter values.  The definition is available by running
    mp_coretable.sas as follows:  `mp_coretable(FILTER_SUMMARY)`. Example
    values:
|FILTER_RK:best.|FILTER_HASH:$32.|FILTER_TABLE:$41.|PROCESSED_DTTM:datetime19.|
|---|---|---|---|
|`1 `|`540E96F566D194AB58DD4C413C99C9DB `|`VIYA6014.MPE_TABLES `|`1956084246 `|
|`2 `|`87737DB9EEE2650F5C89956CEAD0A14F `|`VIYA6014.MPE_X_TEST `|`1956084452.1`|
|`3 `|`8048BD908DBBD83D013560734E90D394 `|`VIYA6014.MPE_TABLES `|`1956093620.6`|
  @param [in] filter_detail= (PERM.FILTER_DETAIL) Permanent table containing
    detailed (raw) filter values. The definition is available by running
    mp_coretable.sas as follows:  `mp_coretable(FILTER_DETAIL)`. Example
    values:
|FILTER_HASH:$32.|FILTER_LINE:best.|GROUP_LOGIC:$3.|SUBGROUP_LOGIC:$3.|SUBGROUP_ID:best.|VARIABLE_NM:$32.|OPERATOR_NM:$12.|RAW_VALUE:$4000.|PROCESSED_DTTM:datetime19.|
|---|---|---|---|---|---|---|---|---|
|`540E96F566D194AB58DD4C413C99C9DB `|`1 `|`AND `|`AND `|`1 `|`LIBREF `|`CONTAINS `|`DC`|`1956084245.8 `|
|`540E96F566D194AB58DD4C413C99C9DB `|`2 `|`AND `|`OR `|`2 `|`DSN `|`= `|` MPE_LOCK_ANYTABLE `|`1956084245.8 `|
|`87737DB9EEE2650F5C89956CEAD0A14F `|`1 `|`AND `|`AND `|`1 `|`PRIMARY_KEY_FIELD `|`IN `|`(1,2,3) `|`1956084451.9 `|
  @param [in] lock_table= (PERM.LOCK_TABLE) Permanent locking table.  Used to
    manage concurrent access.  The definition is available by running
    mp_coretable.sas as follows:  `mp_coretable(LOCKTABLE)`.
  @param [in] maxkeytable= (0) Optional permanent reference table used for
    retained key tracking.  Described in mp_retainedkey.sas.
  @param [in] mdebug= set to 1 to enable DEBUG messages
  @param [out] outresult= The result table with the FILTER_RK
  @param [out] outquery= The original query, taken as extract after table load


  <h4> SAS Macros </h4>
  @li mf_getuniquename.sas
  @li mf_getvalue.sas
  @li mf_islibds.sas
  @li mf_nobs.sas
  @li mp_abort.sas
  @li mp_filtercheck.sas
  @li mp_hashdataset.sas
  @li mp_retainedkey.sas

  <h4> Related Macros </h4>
  @li mp_filtercheck.sas
  @li mp_filtergenerate.sas
  @li mp_filtervalidate.sas
  @li mp_filterstore.test.sas

  @version 9.2
  @author [Allan Bowe](https://www.linkedin.com/in/allanbowe)

**/

%macro mp_filterstore(libds=,
  queryds=work.filterquery,
  filter_summary=PERM.FILTER_SUMMARY,
  filter_detail=PERM.FILTER_DETAIL,
  lock_table=PERM.LOCK_TABLE,
  maxkeytable=PERM.MAXKEYTABLE,
  outresult=work.result,
  outquery=work.query,
  mdebug=1
);
%put &sysmacroname entry vars:;
%put _local_;

%local ds1 ds2 ds3 ds4 filter_hash;
%mp_abort(iftrue= (&syscc ne 0)
  ,mac=mp_filterstore
  ,msg=%str(syscc=&syscc on macro entry)
)
%mp_abort(iftrue= (%mf_islibds(&filter_summary)=0)
  ,mac=mp_filterstore
  ,msg=%str(Invalid filter_summary value: &filter_summary)
)
%mp_abort(iftrue= (%mf_islibds(&filter_detail)=0)
  ,mac=mp_filterstore
  ,msg=%str(Invalid filter_detail value: &filter_detail)
)
%mp_abort(iftrue= (%mf_islibds(&lock_table)=0)
  ,mac=mp_filterstore
  ,msg=%str(Invalid lock_table value: &lock_table)
)

/* validate query */
%mp_filtercheck(&queryds,targetds=&libds,abort=YES)

/* hash the result */
%let ds1=%mf_getuniquename(prefix=hashds);
%mp_hashdataset(&queryds,outds=&ds1,salt=&libds)
%let filter_hash=%upcase(%mf_getvalue(&ds1,hashkey));
%if &mdebug=1 %then %do;
  data _null_;
    putlog "filter_hash=&filter_hash";
    set &ds1;
    putlog (_all_)(=);
  run;
%end;

/* check if data already exists for this hash */
data &outresult;
  set &filter_summary;
  where filter_hash="&filter_hash";
run;

%mp_abort(iftrue= (&syscc ne 0)
  ,mac=mp_filterstore
  ,msg=%str(syscc=&syscc after hash check)
)
%mp_abort(iftrue= ("&filter_hash "=" ")
  ,mac=mp_filterstore
  ,msg=%str(problem with filter_hash generation)
)

%if %mf_nobs(&outresult)=0 %then %do;

  /* first update summary table */
  %let ds3=%mf_getuniquename(prefix=filtersum);
  data work.&ds3;
    if 0 then set &filter_summary;
    filter_table=symget('libds');
    filter_hash="&filter_hash";
    PROCESSED_DTTM=%sysfunc(datetime());
    output;
    stop;
  run;

  %mp_lockanytable(LOCK,
    lib=%scan(&filter_summary,1,.)
    ,ds=%scan(&filter_summary,2,.)
    ,ref=MP_FILTERSTORE summary update - &filter_hash
    ,ctl_ds=&lock_table
  )

  %let ds4=%mf_getuniquename(prefix=filtersumappend);
  %mp_retainedkey(
    base_lib=%scan(&filter_summary,1,.)
    ,base_dsn=%scan(&filter_summary,2,.)
    ,append_lib=work
    ,append_dsn=&ds3
    ,retained_key=filter_rk
    ,business_key=filter_hash
    ,maxkeytable=&maxkeytable
    ,locktable=&lock_table
    ,outds=work.&ds4
  )
  proc append base=&filter_summary data=&ds4;
  run;

  %mp_lockanytable(UNLOCK,
    lib=%scan(&filter_summary,1,.)
    ,ds=%scan(&filter_summary,2,.)
    ,ref=MP_FILTERSTORE summary update - &filter_hash
    ,ctl_ds=&lock_table
  )

  %if &syscc ne 0 %then %do;
    data _null_;
      set &ds4;
      putlog (_all_)(=);
    run;
    %goto err;
  %end;

  data &outresult;
    set &filter_summary;
    where filter_hash="&filter_hash";
  run;

  /* Next, update detail table */
  %let ds2=%mf_getuniquename(prefix=filterdetail);
  data &ds2;
    if 0 then set &filter_detail;
    set &queryds;
    format filter_hash $hex32. filter_line 8.;
    filter_hash="&filter_hash";
    filter_line=_n_;
    PROCESSED_DTTM=%sysfunc(datetime());
  run;
  %mp_lockanytable(LOCK,
    lib=%scan(&filter_detail,1,.)
    ,ds=%scan(&filter_detail,2,.)
    ,ref=MP_FILTERSTORE update - &filter_hash
    ,ctl_ds=&lock_table
  )
  proc append base=&filter_detail data=&ds2;
  run;

  %mp_lockanytable(UNLOCK,
    lib=%scan(&filter_detail,1,.)
    ,ds=%scan(&filter_detail,2,.)
    ,ref=MP_FILTERSTORE detail update &filter_hash
    ,ctl_ds=&lock_table
  )

  %if &syscc ne 0 %then %do;
    data _null_;
      set &ds2;
      putlog (_all_)(=);
    run;
    %goto err;
  %end;

%end;

proc sort data=&filter_detail(where=(filter_hash="&filter_hash")) out=&outquery;
  by filter_line;
run;

%err:
%mp_abort(iftrue= (&syscc ne 0)
  ,mac=mp_filterstore
  ,msg=%str(syscc=&syscc on macro exit)
)

%mend mp_filterstore;/**
  @file
  @brief Checks a generated filter query for validity
  @details Runs a generated filter in proc sql with the validate option.
  Used in mp_filtercheck.sas in an fcmp container.

  Built to support dynamic filtering in
  [Data Controller for SAS&reg;](https://datacontroller.io).

  Usage:

      data work.filtertable;
        infile datalines4 dsd;
        input GROUP_LOGIC:$3. SUBGROUP_LOGIC:$3. SUBGROUP_ID:8. VARIABLE_NM:$32.
          OPERATOR_NM:$10. RAW_VALUE:$4000.;
      datalines4;
      AND,AND,1,AGE,=,12
      AND,AND,1,SEX,<=,"'M'"
      AND,OR,2,Name,NOT IN,"('Jane','Alfred')"
      AND,OR,2,Weight,>=,7
      ;;;;
      run;

      %mp_filtergenerate(work.filtertable,outref=myfilter)

      %mp_filtervalidate(myfilter,sashelp.class)


  @returns The SYSCC value will be 1008 if there are validation issues.

  @param [in] inref The input fileref to validate (generated by
    mp_filtergenerate.sas)
  @param [in] targetds The target dataset against which to verify the query
  @param [out] abort= (YES) If YES will call mp_abort.sas on any exceptions
  @param [out] outds= (work.mp_filtervalidate) Output dataset containing the
    err / warning message, if one exists.  If this table contains any rows,
    there are problems!

  <h4> SAS Macros </h4>
  @li mf_getuniquefileref.sas
  @li mf_nobs.sas
  @li mp_abort.sas

  <h4> Related Macros </h4>
  @li mp_filtercheck.sas
  @li mp_filtergenerate.sas

  @version 9.3
  @author Allan Bowe

**/

%macro mp_filtervalidate(inref,targetds,abort=YES,outds=work.mp_filtervalidate);

%mp_abort(iftrue= (&syscc ne 0 or &syserr ne 0)
  ,mac=&sysmacroname
  ,msg=%str(syscc=&syscc / syserr=&syserr - on macro entry)
)

%local fref1;
%let fref1=%mf_getuniquefileref();

data _null_;
  file &fref1;
  infile &inref end=eof;
  if _n_=1 then do;
    put "proc sql;";
    put "validate select * from &targetds";
    put "where " ;
  end;
  input;
  put _infile_;
  putlog _infile_;
  if eof then put ";quit;";
run;

%inc &fref1;

data &outds;
  if &sqlrc or &syscc or &syserr then do;
    REASON_CD='VALIDATION_ERR'!!'OR: '!!
      coalescec(symget('SYSERRORTEXT'),symget('SYSWARNINGTEXT'));
    output;
  end;
  else stop;
run;

filename &fref1 clear;

%if %mf_nobs(&outds)>0 %then %do;
  %if &abort=YES %then %do;
    data _null_;
      set &outds;
      call symputx('REASON_CD',reason_cd,'l');
      stop;
    run;
    %mp_abort(
      mac=&sysmacroname,
      msg=%str(Filter validation issues. ERR=%superq(SYSERRORTEXT)
        , WARN=%superq(SYSWARNINGTEXT) )
    )
  %end;
  %let syscc=1008;
%end;

%mend mp_filtervalidate;
/**
  @file
  @brief Creates a dataset with column metadata.
  @details This macro takes the `proc contents` output and "tidies it up" in the
  following ways:

    @li Blank labels are filled in with column names
    @li Formats are reconstructed with default values
    @li Types such as DATE / TIME / DATETIME are inferred from the formats

  Example usage:

      %mp_getcols(sashelp.airline,outds=work.myds)

  @param ds The dataset from which to obtain column metadata
  @param outds= (work.cols) The output dataset to create. Sample data:
|NAME:$32.|LENGTH:best.|VARNUM:best.|LABEL:$256.|FMTNAME:$32.|FORMAT:$49.|TYPE:$1.|DDTYPE:$9.|
|---|---|---|---|---|---|---|---|
|`AIR `|`8 `|`2 `|`international airline travel (thousands) `|` `|`8. `|`N `|`NUMERIC `|
|`DATE `|`8 `|`1 `|`DATE `|`MONYY `|`MONYY. `|`N `|`DATE `|
|`REGION `|`3 `|`3 `|`REGION `|` `|`$3. `|`C `|`CHARACTER `|

  <h4> Related Macros </h4>
  @li mf_getvarlist.sas
  @li mm_getcols.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_getcols(ds, outds=work.cols);
%local dropds;
proc contents noprint data=&ds
  out=_data_ (keep=name type length label varnum format:);
run;
%let dropds=&syslast;
data &outds(keep=name type length varnum format label ddtype fmtname);
  set &dropds(rename=(format=fmtname type=type2));
  name=upcase(name);
  if type2=2 then do;
    length format $49.;
    if fmtname='' then format=cats('$',length,'.');
    else if formatl=0 then format=cats(fmtname,'.');
    else format=cats(fmtname,formatl,'.');
    type='C';
    ddtype='CHARACTER';
  end;
  else do;
    if fmtname='' then format=cats(length,'.');
    else if formatl=0 then format=cats(fmtname,'.');
    else if formatd=0 then format=cats(fmtname,formatl,'.');
    else format=cats(fmtname,formatl,'.',formatd);
    type='N';
    if format=:'DATETIME' or format=:'E8601DT' then ddtype='DATETIME';
    else if format=:'DATE' or format=:'DDMMYY' or format=:'MMDDYY'
      or format=:'YYMMDD' or format=:'E8601DA' or format=:'B8601DA'
      or format=:'MONYY'
    then ddtype='DATE';
    else if format=:'TIME' then ddtype='TIME';
    else ddtype='NUMERIC';
  end;
  if label='' then label=name;
run;
proc sql;
drop table &dropds;
%mend mp_getcols;/**
  @file mp_getconstraints.sas
  @brief Get constraint details at column level
  @details Useful for capturing constraints before they are dropped / reapplied
  during an update.

      proc sql;
      create table work.example(
        TX_FROM float format=datetime19.,
        DD_TYPE char(16),
        DD_SOURCE char(2048),
        DD_SHORTDESC char(256),
        constraint pk primary key(tx_from, dd_type,dd_source),
        constraint unq unique(tx_from, dd_type),
        constraint nnn not null(DD_SHORTDESC)
      );

      %mp_getconstraints(lib=work,ds=example,outds=work.constraints)

  @param [in] lib= (WORK) The target library
  @param [in] ds= The target dataset.  Leave blank (default) for all datasets.
  @param [in] mdebug= (0) Set to 1 to preserve temp tables, print var values etc
  @param [out] outds= (mp_getconstraints) the output dataset

  <h4> SAS Macros </h4>
  @li mf_getuniquename.sas
  @li mp_dropmembers.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_getconstraints(lib=WORK
  ,ds=
  ,outds=mp_getconstraints
  ,mdebug=0
)/*/STORE SOURCE*/;

%let lib=%upcase(&lib);
%let ds=%upcase(&ds);

/**
  * Neither dictionary tables nor sashelp provides a constraint order column,
  * however they DO arrive in the correct order.  So, create the col.
  **/
%local vw;
%let vw=%mf_getuniquename(prefix=mp_getconstraints_vw_);
data &vw /view=&vw;
  set sashelp.vcncolu;
  where table_catalog="&lib";

  /* use retain approach to reset the constraint order with each constraint */
  length tmp $1000;
  retain tmp;
  drop tmp;
  if tmp ne catx('|',table_catalog,table_name,constraint_name) then do;
    constraint_order=1;
  end;
  else constraint_order+1;
  tmp=catx('|',table_catalog, table_name,constraint_name);
run;

/* must use SQL as proc datasets does not support length changes */
proc sql noprint;
create table &outds as
  select upcase(a.TABLE_CATALOG) as libref
    ,upcase(a.TABLE_NAME) as TABLE_NAME
    ,a.constraint_type
    ,a.constraint_name
    ,b.column_name
    ,b.constraint_order
  from dictionary.TABLE_CONSTRAINTS a
  left join &vw  b
  on upcase(a.TABLE_CATALOG)=upcase(b.TABLE_CATALOG)
    and upcase(a.TABLE_NAME)=upcase(b.TABLE_NAME)
    and a.constraint_name=b.constraint_name
/**
  * We cannot apply this clause to the underlying dictionary table.  See:
  * https://communities.sas.com/t5/SAS-Programming/Unexpected-Where-Clause-behaviour-in-dictionary-TABLE/m-p/771554#M244867
  */
  where calculated libref="&lib"
  %if "&ds" ne "" %then %do;
    and upcase(a.TABLE_NAME)="&ds"
    and upcase(b.TABLE_NAME)="&ds"
  %end;
  order by libref, table_name, constraint_name, constraint_order
  ;

/* tidy up */
%mp_dropmembers(
  &vw,
  iftrue=(&mdebug=0)
)

%mend mp_getconstraints;/**
  @file
  @brief Extract DBML from SAS Libraries
  @details DBML is an open source markup format to represent databases.
  More details: https://www.dbml.org/home/

  Usage:


      %mp_getdbml(liblist=SASHELP WORK,outref=mydbml,showlog=YES)

  Take the log output and paste it into the renderer at https://dbdiagram.io
  to view your data model diagram.  The code takes a "best guess" at
  the one to one and one to many relationships (based on constraints
  and indexes, and assuming that the column names would match).

  You may need to adjust the rendered DBML to suit your needs.

  ![dbml for sas](https://i.imgur.com/8T1tIZp.gif)


  <h4> SAS Macros </h4>
  @li mf_getquotedstr.sas
  @li mp_getconstraints.sas

  @param liblist= Space seperated list of librefs to take as
    input (Default=SASHELP)
  @param outref= Fileref to contain the DBML (Default=getdbml)
  @param showlog= set to YES to show the DBML in the log (Default is NO)

  @version 9.3
  @author Allan Bowe
**/

%macro mp_getdbml(liblist=SASHELP,outref=getdbml,showlog=NO
)/*/STORE SOURCE*/;

/* check fileref is assigned */
%if %sysfunc(fileref(&outref)) > 0 %then %do;
  filename &outref temp;
%end;

%let liblist=%upcase(&liblist);

proc sql noprint;
create table _data_ as
  select * from dictionary.tables
  where upcase(libname) in (%mf_getquotedstr(&liblist))
  order by libname,memname;
%local tabinfo; %let tabinfo=&syslast;

create table _data_ as
  select * from dictionary.columns
  where upcase(libname) in (%mf_getquotedstr(&liblist))
  order by libname,memname,varnum;
%local colinfo; %let colinfo=&syslast;

%local dsnlist;
  select distinct upcase(cats(libname,'.',memname)) into: dsnlist
  separated by ' '
  from &syslast
;

create table _data_ as
  select * from dictionary.indexes
  where upcase(libname) in (%mf_getquotedstr(&liblist))
  order by idxusage, indxname, indxpos;
%local idxinfo; %let idxinfo=&syslast;

/* Extract all Primary Key and Unique data constraints */
%mp_getconstraints(lib=%scan(&liblist,1),outds=_data_)
%local colconst; %let colconst=&syslast;

%do x=2 %to %sysfunc(countw(&liblist));
  %mp_getconstraints(lib=%scan(&liblist,&x),outds=_data_)
  proc append base=&colconst data=&syslast;
  run;
%end;




/* header info */
data _null_;
  file &outref;
  put "// DBML generated by &sysuserid on %sysfunc(datetime(),datetime19.) ";
  put "Project sasdbml {";
  put "  database_type: 'SAS'";
  put "  Note: 'Generated by the mp_getdbml() macro'";
  put "}";
run;

/* create table groups */
data _null_;
  file &outref mod;
  set &tabinfo;
  by libname;
  if first.libname then put "TableGroup " libname "{";
  ds=quote(cats(libname,'.',memname));
  put '   ' ds;
  if last.libname then put "}";
run;

/* table for pks */
data _data_;
  length curds const col $39;
  call missing (of _all_);
  stop;
run;
%let pkds=&syslast;

%local x curds constraints_used constcheck;
%do x=1 %to %sysfunc(countw(&dsnlist,%str( )));
  %let curds=%scan(&dsnlist,&x,%str( ));
  %let constraints_used=;
  %let constcheck=0;
  data _null_;
    file &outref mod;
    length lab $1024 typ $20;
    set &colinfo (where=(
        libname="%scan(&curds,1,.)" and upcase(memname)="%scan(&curds,2,.)"
    )) end=last;

    if _n_=1 then do;
      table='Table "'!!"&curds"!!'"{';
      put table;
    end;
    name=upcase(name);
    lab=" note:"!!quote(trim(tranwrd(label,'"',"'")));
    if upcase(format)=:'DATETIME' then typ='datetime';
    else if type='char' then typ=cats('char(',length,')');
    else typ='num';

    if notnull='yes' then notnul=' not null';
    if notnull='no' and missing(label) then put '  ' name typ;
    else if notnull='yes' and missing(label) then do;
      put '  ' name typ '[' notnul ']';
    end;
    else if notnull='no' then put '  ' name typ '[' lab ']';
    else put '  ' name typ '[' notnul ',' lab ']';

  run;

  data _data_(keep=curds const col);
    length ctype $11 cols constraints_used $5000;
    set &colconst (where=(
      upcase(libref)="%scan(&curds,1,.)"
      and upcase(table_name)="%scan(&curds,2,.)"
      and constraint_type in ('PRIMARY','UNIQUE')
    )) end=last;
    file &outref mod;
    by constraint_type constraint_name;
    retain cols;
    column_name=upcase(column_name);

    if _n_=1 then put / '  indexes {';

    if upcase(strip(constraint_type)) = 'PRIMARY' then ctype='[pk]';
    else ctype='[unique]';

    if first.constraint_name then cols = cats('(',column_name);
    else cols=cats(cols,',',column_name);

    if last.constraint_name then do;
      cols=cats(cols,')',ctype)!!' //'!!constraint_name;
      put '    ' cols;
      constraints_used=catx(' ',constraints_used, constraint_name);
      call symputx('constcheck',1);
    end;

    if last then call symput('constraints_used',cats(upcase(constraints_used)));

    length curds const col $39;
    curds="&curds";
    const=constraint_name;
    col=column_name;
  run;

  proc append base=&pkds data=&syslast;run;

  /* Create Unique Indexes, but only if they were not already defined within
    the Constraints section. */
  data _data_(keep=curds const col);
    set &idxinfo (where=(
      libname="%scan(&curds,1,.)"
      and upcase(memname)="%scan(&curds,2,.)"
      and unique='yes'
      and upcase(indxname) not in (%mf_getquotedstr(&constraints_used))
    ));
    file &outref mod;
    by idxusage indxname;
    name=upcase(name);
    if &constcheck=1 then stop; /* we only care about PKs so stop if we have */
    if _n_=1 and &constcheck=0 then put / '  indexes {';

    length cols $5000;
    retain cols;
    if first.indxname then cols = cats('(',name);
    else cols=cats(cols,',',name);

    if last.indxname then do;
      cols=cats(cols,')[unique]')!!' //'!!indxname;
      put '    ' cols;
      call symputx('constcheck',1);
    end;

    length curds const col $39;
    curds="&curds";
    const=indxname;
    col=name;
  run;
  proc append base=&pkds data=&syslast;run;

  data _null_;
    file &outref mod;
    if &constcheck =1 then put '  }';
    put '}';
  run;

%end;

/**
  * now we need to figure out the relationships
  */

/* sort alphabetically so we can have one set of unique cols per table */
proc sort data=&pkds nodupkey;
  by curds const col;
run;

data &pkds.1 (keep=curds col)
    &pkds.2 (keep=curds cols);
  set &pkds;
  by curds const;
  length retconst $39 cols $5000;
  retain retconst cols;
  if first.curds then do;
    retconst=const;
    cols=upcase(col);
  end;
  else cols=catx(' ',cols,upcase(col));
  if retconst=const then do;
    output &pkds.1;
    if last.const then output &pkds.2;
  end;
run;

%let curdslist="0";
%do x=1 %to %sysfunc(countw(&dsnlist,%str( )));
  %let curds=%scan(&dsnlist,&x,%str( ));

  %let pkcols=0;
  data _null_;
    set &pkds.2(where=(curds="&curds"));
    call symputx('pkcols',cols);
  run;
  %if &pkcols ne 0 %then %do;
    %let curdslist=&curdslist,"&curds";

    /* start with one2one */
    data &pkds.4;
      file &outref mod;
      set &pkds.2(where=(cols="&pkcols" and curds not in (&curdslist)));
      line='Ref: "'!!"&curds"
        !!cats('".(',"%mf_getquotedstr(&pkcols,dlm=%str(,),quote=%str( ))",')')
        !!' - '
        !!cats(quote(trim(curds))
            ,'.('
            ,"%mf_getquotedstr(&pkcols,dlm=%str(,),quote=%str( ))"
            ,')'
          );
      put line;
    run;

    /* now many2one */
    /* get table with one row per col */
    data &pkds.5;
      set &pkds.1(where=(curds="&curds"));
    run;
    /* get tables which contain the PK columns */
    proc sql;
    create table &pkds.5a as
      select upcase(cats(b.libname,'.',b.memname)) as curds
        ,b.name
      from &pkds.5 a
      inner join &colinfo b
      on a.col=upcase(b.name);
    /* count to make sure those tables contain ALL the columns */
    create table &pkds.5b as
      select curds,count(*) as cnt
      from &pkds.5a
      where curds not in (
          select curds from &pkds.2 where cols="&pkcols"
        ) /* not a one to one match */
        and curds ne "&curds" /* exclude self */
      group by 1;
    create table &pkds.6 as
      select a.*
        ,b.cols
      from &pkds.5b a
      left join &pkds.4 b
      on a.curds=b.curds;

    data _null_;
      set &pkds.6;
      file &outref mod;
      colcnt=%sysfunc(countw(&pkcols));
      if cnt=colcnt then do;
        /* table contains all the PK cols, and was not a direct / 121 match */
        line='Ref: "'!!"&curds"
          !!'".('
          !!"%mf_getquotedstr(&pkcols,dlm=%str(,),quote=%str( ))"
          !!') > '
          !!cats(quote(trim(curds))
              ,'.('
              ,"%mf_getquotedstr(&pkcols,dlm=%str(,),quote=%str( ))"
              ,')'
          );
        put line;
      end;
    run;
  %end;
%end;


%if %upcase(&showlog)=YES %then %do;
  options ps=max;
  data _null_;
    infile &outref;
    input;
    putlog _infile_;
  run;
%end;

%mend mp_getdbml;/**
  @file mp_getddl.sas
  @brief Extract DDL in various formats, by table or library
  @details Data Definition Language relates to a set of SQL instructions used
    to create tables in SAS or a database.  The macro can be used at table or
    library level.  The default behaviour is to create DDL in SAS format.

    Note - views are not currently supported.

  Usage:

      data test(index=(pk=(x y)/unique /nomiss));
        x=1;
        y='blah';
        label x='blah';
      run;
      proc sql; describe table &syslast;
      %mp_getddl(work,test,flavour=tsql,showlog=YES)

  <h4> SAS Macros </h4>
  @li mf_existfileref.sas
  @li mf_getvarcount.sas
  @li mp_getconstraints.sas

  @param lib libref of the library to create DDL for.  Should be assigned.
  @param ds dataset to create ddl for (optional)
  @param fref= the fileref to which to _append_ the DDL.  If it does not exist,
    it will be created.
  @param flavour= The type of DDL to create (default=SAS). Supported=TSQL
  @param showlog= Set to YES to show the DDL in the log
  @param schema= Choose a preferred schema name (default is to use actual schema
    ,else libref)
  @param applydttm= for non SAS DDL, choose if columns are created with native
    datetime2 format or regular decimal type
  @version 9.3
  @author Allan Bowe
**/

%macro mp_getddl(libref,ds,fref=getddl,flavour=SAS,showlog=NO,schema=
  ,applydttm=NO
)/*/STORE SOURCE*/;

/* check fileref is assigned */
%if %mf_existfileref(&fref)=0 %then %do;
  filename &fref temp ;
%end;

%if %length(&libref)=0 %then %let libref=WORK;
%let flavour=%upcase(&flavour);

proc sql noprint;
create table _data_ as
  select * from dictionary.tables
  where upcase(libname)="%upcase(&libref)"
    and memtype='DATA' /* views not currently supported */
  %if %length(&ds)>0 %then %do;
    and upcase(memname)="%upcase(&ds)"
  %end;
  ;
%local tabinfo; %let tabinfo=&syslast;

create table _data_ as
  select * from dictionary.columns
  where upcase(libname)="%upcase(&libref)"
  %if %length(&ds)>0 %then %do;
    and upcase(memname)="%upcase(&ds)"
  %end;
  ;
%local colinfo; %let colinfo=&syslast;

%local dsnlist;
  select distinct upcase(memname) into: dsnlist
  separated by ' '
  from &syslast
;

create table _data_ as
  select * from dictionary.indexes
  where upcase(libname)="%upcase(&libref)"
  %if %length(&ds)>0 %then %do;
    and upcase(memname)="%upcase(&ds)"
  %end;
  order by idxusage, indxname, indxpos
  ;
%local idxinfo; %let idxinfo=&syslast;

/* Extract all Primary Key and Unique data constraints */
%mp_getconstraints(lib=%upcase(&libref),ds=%upcase(&ds),outds=_data_)
%local colconst; %let colconst=&syslast;

%macro addConst();
  %global constraints_used;
  data _null_;
    length ctype $11 constraint_name_orig $256 constraints_used $5000;
    set &colconst(
        where=(table_name="&curds" and constraint_type in ('PRIMARY','UNIQUE'))
      ) end=last;
    file &fref mod;
    by constraint_type constraint_name;
    retain constraints_used;
    constraint_name_orig=constraint_name;
    if upcase(strip(constraint_type)) = 'PRIMARY' then ctype='PRIMARY KEY';
    else ctype=strip(constraint_type);
    %if &flavour=TSQL %then %do;
      column_name=catt('[',column_name,']');
      constraint_name=catt('[',constraint_name,']');
    %end;
    %else %if &flavour=PGSQL %then %do;
      column_name=catt('"',column_name,'"');
      constraint_name=catt('"',constraint_name,'"');
    %end;
    if first.constraint_name then do;
      constraints_used = catx(' ', constraints_used, constraint_name_orig);
      put "   ,CONSTRAINT " constraint_name ctype "(" ;
      put '     ' column_name;
    end;
  else put '     ,' column_name;
  if last.constraint_name then do;
    put "   )";
    call symput('constraints_used',strip(constraints_used));
  end;
  run;
  %put &=constraints_used;
%mend addConst;

data _null_;
  file &fref mod;
  put "/* DDL generated by &sysuserid on %sysfunc(datetime(),datetime19.) */";
run;

%local x curds;
%if &flavour=SAS %then %do;
  data _null_;
    file &fref mod;
    put "/* SAS Flavour DDL for %upcase(&libref).&curds */";
    put "proc sql;";
  run;
  %do x=1 %to %sysfunc(countw(&dsnlist));
    %let curds=%scan(&dsnlist,&x);
    data _null_;
      file &fref mod;
      length lab $1024 typ $20;
      set &colinfo (where=(upcase(memname)="&curds")) end=last;

      if _n_=1 then do;
        if memtype='DATA' then do;
          put "create table &libref..&curds(";
        end;
        else do;
          /* just a placeholder - we filter out views at the top */
          put "create view &libref..&curds(";
        end;
        put "    "@@;
      end;
      else put "   ,"@@;
      if length(format)>1 then fmt=" format="!!cats(format);
      if length(label)>1 then
        lab=" label="!!cats("'",tranwrd(label,"'","''"),"'");
      if notnull='yes' then notnul=' not null';
      if type='char' then typ=cats('char(',length,')');
      else if length ne 8 then typ='num length='!!left(length);
      else typ='num';
      put name typ fmt notnul lab;
    run;

    /* Extra step for data constraints */
    %addConst()

    data _null_;
      file &fref mod;
      put ');';
    run;

    /* Create Unique Indexes, but only if they were not already defined within
      the Constraints section. */
    data _null_;
      *length ds $128;
      set &idxinfo(
        where=(
          memname="&curds"
          and unique='yes'
          and indxname not in (
              %sysfunc(tranwrd("&constraints_used",%str( ),%str(",")))
              )
          )
        );
      file &fref mod;
      by idxusage indxname;
/*       ds=cats(libname,'.',memname); */
      if first.indxname then do;
          put 'CREATE UNIQUE INDEX ' indxname "ON &libref..&curds (" ;
          put '  ' name ;
      end;
      else put '  ,' name ;
      *else put '    ,' name ;
      if last.indxname then do;
        put ');';
      end;
    run;

/*
    ods output IntegrityConstraints=ic;
    proc contents data=testali out2=info;
    run;
    */
  %end;
%end;
%else %if &flavour=TSQL %then %do;
  /* if schema does not exist, set to be same as libref */
  %local schemaactual;
  proc sql noprint;
  select sysvalue into: schemaactual
    from dictionary.libnames
    where upcase(libname)="&libref" and engine='SQLSVR';
  %let schema=%sysfunc(coalescec(&schemaactual,&schema,&libref));

  %do x=1 %to %sysfunc(countw(&dsnlist));
    %let curds=%scan(&dsnlist,&x);
    data _null_;
      file &fref mod;
      put "/* TSQL Flavour DDL for &schema..&curds */";
    data _null_;
      file &fref mod;
      set &colinfo (where=(upcase(memname)="&curds")) end=last;
      if _n_=1 then do;
        if memtype='DATA' then do;
          put "create table [&schema].[&curds](";
        end;
        else do;
          /* just a placeholder - we filter out views at the top */
          put "create view [&schema].[&curds](";
        end;
        put "    "@@;
      end;
      else put "   ,"@@;
      format=upcase(format);
      if 1=0 then; /* dummy if */
      %if &applydttm=YES %then %do;
        else if format=:'DATETIME' then fmt='[datetime2](7)  ';
      %end;
      else if type='num' then fmt='[decimal](18,2)';
      else if length le 8000 then fmt='[varchar]('!!cats(length)!!')';
      else fmt=cats('[varchar](max)');
      if notnull='yes' then notnul=' NOT NULL';
      put "[" name +(-1) "]" fmt notnul;
    run;

    /* Extra step for data constraints */
    %addConst()

    /* Create Unique Indexes, but only if they were not already defined within
      the Constraints section. */
    data _null_;
      *length ds $128;
      set &idxinfo(
        where=(
          memname="&curds"
          and unique='yes'
          and indxname not in (
            %sysfunc(tranwrd("&constraints_used",%str( ),%str(",")))
          )
        )
      );
      file &fref mod;
      by idxusage indxname;
      *ds=cats(libname,'.',memname);
      if first.indxname then do;
        /* add nonclustered in case of multiple unique indexes */
        put '   ,index [' indxname +(-1) '] UNIQUE NONCLUSTERED (';
        put '     [' name +(-1) ']';
      end;
      else put '     ,[' name +(-1) ']';
      if last.indxname then do;
        put '   )';
      end;
    run;

    data _null_;
      file &fref mod;
      put ')';
      put 'GO';
    run;

    /* add extended properties for labels */
    data _null_;
      file &fref mod;
      length nm $64 lab $1024;
      set &colinfo (where=(upcase(memname)="&curds" and label ne '')) end=last;
      nm=cats("N'",tranwrd(name,"'","''"),"'");
      lab=cats("N'",tranwrd(label,"'","''"),"'");
      put ' ';
      put "EXEC sys.sp_addextendedproperty ";
      put "  @name=N'MS_Description',@value=" lab ;
      put "  ,@level0type=N'SCHEMA',@level0name=N'&schema' ";
      put "  ,@level1type=N'TABLE',@level1name=N'&curds'";
      put "  ,@level2type=N'COLUMN',@level2name=" nm ;
      if last then put 'GO';
    run;
  %end;
%end;
%else %if &flavour=PGSQL %then %do;
  /* if schema does not exist, set to be same as libref */
  %local schemaactual;
  proc sql noprint;
  select sysvalue into: schemaactual
    from dictionary.libnames
    where upcase(libname)="&libref" and engine='POSTGRES';
  %let schema=%sysfunc(coalescec(&schemaactual,&schema,&libref));
  data _null_;
    file &fref mod;
    put "CREATE SCHEMA &schema;";
  %do x=1 %to %sysfunc(countw(&dsnlist));
    %let curds=%scan(&dsnlist,&x);
    %local curdsvarcount;
    %let curdsvarcount=%mf_getvarcount(&libref..&curds);
    %if &curdsvarcount>1600 %then %do;
      data _null_;
        file &fref mod;
        put "/* &libref..&curds contains &curdsvarcount vars */";
        put "/* Postgres cannot create tables with over 1600 vars */";
        put "/* No DDL will be generated for this table";
      run;
    %end;
    %else %do;
      data _null_;
        file &fref mod;
        put "/* Postgres Flavour DDL for &schema..&curds */";
      data _null_;
        file &fref mod;
        set &colinfo (where=(upcase(memname)="&curds")) end=last;
        length fmt $32;
        if _n_=1 then do;
          if memtype='DATA' then do;
            put "CREATE TABLE &schema..&curds (";
          end;
          else do;
            /* just a placeholder - we filter out views at the top */
            put "CREATE VIEW &schema..&curds (";
          end;
          put "    "@@;
        end;
        else put "   ,"@@;
        format=upcase(format);
        if 1=0 then; /* dummy if */
        %if &applydttm=YES %then %do;
          else if format=:'DATETIME' then fmt=' TIMESTAMP ';
        %end;
        else if type='num' then fmt=' DOUBLE PRECISION';
        else fmt='VARCHAR('!!cats(length)!!')';
        if notnull='yes' then notnul=' NOT NULL';
        /* quote column names in case they represent reserved words */
        name2=quote(trim(name));
        put name2 fmt notnul;
      run;

      /* Extra step for data constraints */
      %addConst()

      data _null_;
        file &fref mod;
        put ');';
      run;

      /* Create Unique Indexes, but only if they were not already defined within
        the Constraints section. */
      data _null_;
        *length ds $128;
        set &idxinfo(
          where=(
            memname="&curds"
            and unique='yes'
            and indxname not in (
              %sysfunc(tranwrd("&constraints_used",%str( ),%str(",")))
            )
          )
        );
        file &fref mod;
        by idxusage indxname;
        if first.indxname then do;
          put 'CREATE UNIQUE INDEX "' indxname +(-1) '" ' "ON &schema..&curds(";
          put '  "' name +(-1) '"' ;
        end;
        else put '  ,"' name +(-1) '"';
        if last.indxname then do;
          put ');';
        end;
      run;
    %end;
  %end;
%end;
%if %upcase(&showlog)=YES %then %do;
  options ps=max;
  data _null_;
    infile &fref;
    input;
    putlog _infile_;
  run;
%end;

%mend mp_getddl;/**
  @file
  @brief Export format definitions
  @details Formats are exported from the first (if any) catalog entry in the
  FMTSEARCH path.

  Formats are taken from the library / dataset reference and / or a static
  format list.

  Example usage:

      %mp_getformats(lib=sashelp,ds=prdsale,outsummary=work.dictable)

  @param [in] lib= (0) The libref for which to return formats.
  @todo Enable exporting of formats for an entire library
  @param [in] ds= (0) The dataset from which to obtain format definitions
  @param [in] fmtlist= (0) A list of additional format names
  @param [out] outsummary= (work.mp_getformats_summary) Output dataset
    containing summary definitions - structure taken from dictionary.formats as
    follows:

  |libname:$8.|memname:$32.|path:$1024.|objname:$32.|fmtname:$32.|fmttype:$1.|source:$1.|minw:best.|mind:best.|maxw:best.|maxd:best.|defw:best.|defd:best.|
  |---|---|---|---|---|---|---|---|---|---|---|---|---|
  | | | | |$|F|B|1|0|32767|0|1|0|
  | | | | |$|I|B|1|0|32767|0|1|0|
  |` `|` `|/opt/sas/sas9/SASHome/SASFoundation/9.4/sasexe|UWIANYDT|$ANYDTIF|I|U|1|0|60|0|19|0|
  | | |/opt/sas/sas9/SASHome/SASFoundation/9.4/sasexe|UWFASCII|$ASCII|F|U|1|0|32767|0|1|0|
  | | |/opt/sas/sas9/SASHome/SASFoundation/9.4/sasexe|UWIASCII|$ASCII|I|U|1|0|32767|0|1|0|
  | | |/opt/sas/sas9/SASHome/SASFoundation/9.4/sasexe|UWFBASE6|$BASE64X|F|U|1|0|32767|0|1|0|


  @param [out] outdetail= (0) Provide an output dataset in which to export all
    the custom format definitions (from proc format CNTLOUT).  Definitions:
https://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473477.htm
    Sample data:

  |FMTNAME:$32.|START:$16.|END:$16.|LABEL:$256.|MIN:best.|MAX:best.|DEFAULT:best.|LENGTH:best.|FUZZ:best.|PREFIX:$2.|MULT:best.|FILL:$1.|NOEDIT:best.|TYPE:$1.|SEXCL:$1.|EEXCL:$1.|HLO:$13.|DECSEP:$1.|DIG3SEP:$1.|DATATYPE:$8.|LANGUAGE:$8.|
  |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
  |`WHICHPATH `|`0 `|`0 `|`path1 `|`1 `|`40 `|`28 `|`28 `|`1E-12 `|` `|`0 `|` `|`0 `|`N `|`N `|`N `|` `|` `|` `|` `|` `|
  |`WHICHPATH `|`**OTHER** `|`**OTHER** `|`big fat problem if not path1 `|`1 `|`40 `|`28 `|`28 `|`1E-12 `|` `|`0 `|` `|`0 `|`N `|`N `|`N `|`O `|` `|` `|` `|` `|

  <h4> SAS Macros </h4>
  @li mf_dedup.sas
  @li mf_getfmtlist.sas
  @li mf_getfmtname.sas
  @li mf_getquotedstr.sas
  @li mf_getuniquename.sas


  <h4> Related Macros </h4>
  @li mp_applyformats.sas
  @li mp_getformats.test.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_getformats(lib=0
  ,ds=0
  ,fmtlist=0
  ,outsummary=work.mp_getformats_summary
  ,outdetail=0
);

%local i fmt allfmts tempds fmtcnt;

%if "&fmtlist" ne "0" %then %do i=1 %to %sysfunc(countw(&fmtlist,,%str( )));
  /* ensure format list contains format _name_ only */
  %let fmt=%scan(&fmtlist,&i,%str( ));
  %let fmt=%mf_getfmtname(&fmt);
  %let allfmts=&allfmts &fmt;
%end;

%if &ds=0 and &lib ne 0 %then %do;
  /* grab formats from library */
  /* to do */
%end;
%else %if &ds ne 0 and &lib ne 0 %then %do;
  /* grab formats from dataset */
  %let allfmts=%mf_getfmtlist(&lib..&ds) &allfmts;
%end;

/* ensure list is unique */
%let allfmts=%mf_dedup(%upcase(&allfmts));

/* create summary table */
%if %index(&outsummary,.)=0 %then %let outsummary=WORK.&outsummary;
proc sql;
create table &outsummary as
  select * from dictionary.formats
  where fmtname in (%mf_getquotedstr(&allfmts,quote=D))
    and fmttype='F';

%if "&outdetail" ne "0" %then %do;
  /* ensure base table always exists */
  proc sql;
  create table &outdetail(
      FMTNAME char(32)     label='Format name'
      ,START char(16)     label='Starting value for format'
      ,END char(16)     label='Ending value for format'
      ,LABEL char(256)     label='Format value label'
      ,MIN num length=3     label='Minimum length'
      ,MAX num length=3     label='Maximum length'
      ,DEFAULT num length=3     label='Default length'
      ,LENGTH num length=3     label='Format length'
      ,FUZZ num     label='Fuzz value'
      ,PREFIX char(2)     label='Prefix characters'
      ,MULT num     label='Multiplier'
      ,FILL char(1)     label='Fill character'
      ,NOEDIT num length=3     label='Is picture string noedit?'
      ,TYPE char(1)     label='Type of format'
      ,SEXCL char(1)     label='Start exclusion'
      ,EEXCL char(1)     label='End exclusion'
      ,HLO char(13)     label='Additional information'
      ,DECSEP char(1)     label='Decimal separator'
      ,DIG3SEP char(1)     label='Three-digit separator'
      ,DATATYPE char(8)     label='Date/time/datetime?'
      ,LANGUAGE char(8)     label='Language for date strings'
  );
  /* grab the location of each format */
  %let fmtcnt=0;
  data _null_;
    set &outsummary;
    if not missing(libname);
    x+1;
    call symputx(cats('fmtloc',x),cats(libname,'.',memname),'l');
    call symputx(cats('fmtname',x),fmtname,'l');
    call symputx('fmtcnt',x,'l');
  run;
  /* export each format and append to the output table */
  %let tempds=%mf_getuniquename(prefix=mp_getformats);
  %do i=1 %to &fmtcnt;
    proc format library=&&fmtloc&i CNTLOUT=&tempds;
      select &&fmtname&i;
    run;
    proc append base=&outdetail data=&tempds;
    run;
  %end;
%end;

%mend mp_getformats;/**
  @file mp_getmaxvarlengths.sas
  @brief Scans a dataset to find the max length of the variable values
  @details
  This macro will scan a base dataset and produce an output dataset with two
  columns:

  - NAME    Name of the base dataset column
  - MAXLEN Maximum length of the data contained therein.

  Character fields may be allocated very large widths (eg 32000) of which the
  maximum  value is likely to be much narrower.  This macro was designed to
  enable a HTML table to be appropriately sized however this could be used as
  part of a data audit to ensure we aren't over-sizing our tables in relation to
  the data therein.

  Numeric fields are converted using the relevant format to determine the width.
  Usage:

      %mp_getmaxvarlengths(sashelp.class,outds=work.myds)

  @param libds Two part dataset (or view) reference.
  @param outds= The output dataset to create

  <h4> SAS Macros </h4>
  @li mf_getvarlist.sas
  @li mf_getvartype.sas
  @li mf_getvarformat.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_getmaxvarlengths(
    libds      /* libref.dataset to analyse */
    ,outds=work.mp_getmaxvarlengths /* name of output dataset to create */
)/*/STORE SOURCE*/;

%local vars x var fmt;
%let vars=%mf_getvarlist(libds=&libds);

proc sql;
create table &outds (rename=(
    %do x=1 %to %sysfunc(countw(&vars,%str( )));
      ________&x=%scan(&vars,&x)
    %end;
    ))
  as select
    %do x=1 %to %sysfunc(countw(&vars,%str( )));
      %let var=%scan(&vars,&x);
      %if &x>1 %then ,;
      %if %mf_getvartype(&libds,&var)=C %then %do;
        max(length(&var)) as ________&x
      %end;
      %else %do;
        %let fmt=%mf_getvarformat(&libds,&var);
        %put fmt=&fmt;
        %if %str(&fmt)=%str() %then %do;
          max(length(cats(&var))) as ________&x
        %end;
        %else %do;
          max(length(put(&var,&fmt))) as ________&x
        %end;
      %end;
    %end;
  from &libds;

  proc transpose data=&outds
    out=&outds(rename=(_name_=NAME COL1=MAXLEN));
  run;

%mend mp_getmaxvarlengths;/**
  @file
  @brief Extract the primary key fields from a table or library
  @details Examines the constraints to identify primary key fields - indicated
  by an explicit PK constraint, or a unique index that is also NOT NULL.

  Can be executed at both table and library level.  Supports both BASE engine
  libraries and SQL Server.

  Usage:

      proc sql;
      create table work.example(
        TX_FROM float format=datetime19.,
        DD_TYPE char(16),
        DD_SOURCE char(2048),
        DD_SHORTDESC char(256),
        constraint pk primary key(tx_from, dd_type,dd_source),
        constraint unq unique(tx_from, dd_type),
        constraint nnn not null(DD_SHORTDESC)
      );
      %mp_getpk(work,ds=example)

  Returns:

|libref:$8.|dsn:$32.|memtype:$8.|dbms_memtype:$32.|typemem:$8.|memlabel:$256.|nvar:best.|compress:$8.|pk_fields:$512.|
|---|---|---|---|---|---|---|---|---|
|WORK|EXAMPLE|DATA| |DATA| |4|NO|TX_FROM DD_TYPE DD_SOURCE|


  @param [in] lib The libref to examine
  @param [in] ds= (0) Select the dataset to examine, else use 0 for all tables
  @param [in] mdebug= (0) Set to 1 to preserve temp tables, print var values etc
  @param [out] outds= (work.mp_getpk) The name of the output table to create.

  <h4> SAS Macros </h4>
  @li mf_getengine.sas
  @li mf_getschema.sas
  @li mp_dropmembers.sas
  @li mp_getconstraints.sas

  <h4> Related Macros </h4>
  @li mp_getpk.test.sas
  @li mp_guesspk.sas

  @version 9.3
  @author Macro People Ltd
**/

%macro mp_getpk(
  lib,
  ds=0,
  outds=work.mp_getpk,
  mdebug=0
)/*/STORE SOURCE*/;


%local engine schema ds1 ds2 ds3 dsn tabs1 tabs2 sum pk4sure pkdefault finalpks;

%let lib=%upcase(&lib);
%let ds=%upcase(&ds);
%let engine=%mf_getengine(&lib);
%let schema=%mf_getschema(&lib);

%let ds1=%mf_getuniquename(prefix=getpk_ds1);
%let ds2=%mf_getuniquename(prefix=getpk_ds2);
%let ds3=%mf_getuniquename(prefix=getpk_ds3);
%let tabs1=%mf_getuniquename(prefix=getpk_tabs1);
%let tabs2=%mf_getuniquename(prefix=getpk_tabs2);
%let sum=%mf_getuniquename(prefix=getpk_sum);
%let pk4sure=%mf_getuniquename(prefix=getpk_pk4sure);
%let pkdefault=%mf_getuniquename(prefix=getpk_pkdefault);
%let finalpks=%mf_getuniquename(prefix=getpk_finalpks);

%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

proc sql;
create table &ds1 as
  select  libname as libref
    ,upcase(memname) as dsn
    ,memtype
    ,upcase(name) as name
    ,type
    ,length
    ,varnum
    ,label
    ,format
    ,idxusage
    ,notnull
  from dictionary.columns
  where upcase(libname)="&lib"
%if &ds ne 0 %then %do;
    and upcase(memname)="&ds"
%end;
  ;


%if &engine=SQLSVR %then %do;
  proc sql;
  connect using &lib;
  create table work.&ds2 as
  select * from connection to &lib(
  select
      s.name as SchemaName,
      t.name as memname,
      tc.name as name,
      ic.key_ordinal as KeyOrderNr
  from
      sys.schemas s
      inner join sys.tables t   on s.schema_id=t.schema_id
      inner join sys.indexes i  on t.object_id=i.object_id
      inner join sys.index_columns ic on i.object_id=ic.object_id
                                    and i.index_id=ic.index_id
      inner join sys.columns tc on ic.object_id=tc.object_id
                              and ic.column_id=tc.column_id
  where i.is_primary_key=1
    and s.name=%str(%')&schema%str(%')
  order by t.name, ic.key_ordinal ;
  );disconnect from &lib;
  create table &ds3 as
    select a.*
      ,case when b.name is not null then 1 else 0 end as pk_ind
    from work.&ds1 a
    left join work.&ds2 b
    on a.dsn=b.memname
      and upcase(a.name)=upcase(b.name)
    order by libref,dsn;
%end;
%else %do;

  %if &ds = 0 %then %let dsn=;

  /* get all constraints, in constraint order*/
  %mp_getconstraints(lib=&lib,ds=&dsn,outds=work.&ds2)

  /* extract cols that are clearly primary keys */
  proc sql;
  create table &pk4sure as
    select libref
      ,table_name
      ,constraint_name
      ,constraint_order
      ,column_name as name
    from work.&ds2
    where constraint_type='PRIMARY'
    order by 1,2,3,4;

  /* extract unique constraints where every col is also NOT NULL */
  proc sql;
  create table &sum as
    select a.libref
      ,a.table_name
      ,a.constraint_name
      ,count(a.column_name) as unq_cnt
      ,count(b.column_name) as nul_cnt
    from work.&ds2(where=(constraint_type ='UNIQUE')) a
    left join work.&ds2(where=(constraint_type ='NOT NULL')) b
    on a.libref=b.libref
      and a.table_name=b.table_name
      and a.column_name=b.column_name
    group by 1,2,3
    having unq_cnt=nul_cnt;

  /* extract cols from the relevant unique constraints */
  create table &pkdefault as
    select a.libref
      ,a.table_name
      ,a.constraint_name
      ,b.constraint_order
      ,b.column_name as name
    from &sum a
    left join &ds2(where=(constraint_type ='UNIQUE')) b
    on a.libref=b.libref
      and a.table_name=b.table_name
      and a.constraint_name=b.constraint_name
    order by 1,2,3,4;

  /* create one table */
  data &finalpks;
    set &pkdefault &pk4sure ;
    pk_ind=1;
    /* if there are multiple unique constraints, take the first */
    by libref table_name constraint_name;
    retain keepme;
    if first.table_name then keepme=1;
    if first.constraint_name and not first.table_name then keepme=0;
    if keepme=1;
  run;

  /* join back to starting table */
  proc sql;
  create table &ds3 as
    select a.*
      ,b.constraint_order
      ,case when b.pk_ind=1 then 1 else 0 end as pk_ind
    from work.&ds1 a
    left join work.&finalpks b
    on a.libref=b.libref
      and a.dsn=b.table_name
      and upcase(a.name)=upcase(b.name)
    order by libref,dsn,constraint_order;
%end;


/* prepare tables */
proc sql;
create table work.&tabs1 as select
  libname as libref
  ,upcase(memname) as dsn
  ,memtype
  ,dbms_memtype
  ,typemem
  ,memlabel
  ,nvar
  ,compress
from dictionary.tables
  where upcase(libname)="&lib"
%if &ds ne 0 %then %do;
    and upcase(memname)="&ds"
%end;
  ;
data &tabs2;
  set &ds3;
  length pk_fields $512;
  retain pk_fields;
  by libref dsn constraint_order;
  if first.dsn then pk_fields='';
  if pk_ind=1 then pk_fields=catx(' ',pk_fields,name);
  if last.dsn then output;
run;

proc sql;
create table &outds as
  select a.libref
    ,a.dsn
    ,a.memtype
    ,a.dbms_memtype
    ,a.typemem
    ,a.memlabel
    ,a.nvar
    ,a.compress
    ,b.pk_fields
  from work.&tabs1 a
  left join work.&tabs2 b
  on a.libref=b.libref
    and a.dsn=b.dsn;

/* tidy up */
%mp_dropmembers(
  &ds1 &ds2 &ds3 &dsn &tabs1 &tabs2 &sum &pk4sure &pkdefault &finalpks,
  iftrue=(&mdebug=0)
)

%mend mp_getpk;/**
  @file
  @brief Performs a text substitution on a file
  @details Makes use of the GSUB function in LUA to perform a text substitution
  in a file - either in-place, or writing to a new location.  The benefit of
  using LUA is that the entire file can be loaded into a single variable,
  thereby side stepping the 32767 character limit in a data step.

  Usage:

      %let file=%sysfunc(pathname(work))/file.txt;
      %let str=replace/me;
      %let rep=with/this;
      data _null_;
        file "&file";
        put "&str";
      run;
      %mp_gsubfile(file=&file, patternvar=str, replacevar=rep)
      data _null_;
        infile "&file";
        input;
        list;
      run;

  @param file= (0) The file to perform the substitution on
  @param patternvar= A macro variable containing the Lua
    [pattern](https://www.lua.org/pil/20.2.html) to search for.  Due to the use
    of special (magic) characters in Lua patterns, it is safer to pass the NAME
    of the macro variable containing the string, rather than the value itself.
  @param replacevar= The name of the macro variable containing the replacement
    _string_.
  @param outfile= (0) The file to write the output to. If zero, then the file
    is overwritten in-place.

  <h4> SAS Macros </h4>
  @li ml_gsubfile.sas

  <h4> Related Macros </h4>
  @li mp_gsubfile.test.sas

  @version 9.4
  @author Allan Bowe
**/

%macro mp_gsubfile(file=0,
  patternvar=,
  replacevar=,
  outfile=0
)/*/STORE SOURCE*/;

  %ml_gsubfile()

%mend mp_gsubfile;
/**
  @file
  @brief Guess the primary key of a table
  @details Tries to guess the primary key of a table based on the following
  logic:

      * Columns with nulls are ignored
      * Return only column combinations that provide unique results
      * Start from one column, then move out to composite keys of 2 to 6 columns

  The library of the target should be assigned before using this macro.

  Usage:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;
      %mp_guesspk(sashelp.class,outds=classpks)

  @param baseds The dataset to analyse
  @param outds= The output dataset to contain the possible PKs
  @param max_guesses= (3) The total number of possible primary keys to generate.
    A table may have multiple unlikely PKs, so no need to list them all.
  @param min_rows= (5) The minimum number of rows a table should have in order
    to try and guess the PK.

  <h4> SAS Macros </h4>
  @li mf_getvarlist.sas
  @li mf_getuniquename.sas
  @li mf_nobs.sas

  <h4> Related Macros </h4>
  @li mp_getpk.sas

  @version 9.3
  @author Allan Bowe

**/

%macro mp_guesspk(baseds
      ,outds=mp_guesspk
      ,max_guesses=3
      ,min_rows=5
)/*/STORE SOURCE*/;

  /* declare local vars */
  %local var vars vcnt i j k l tmpvar tmpds rows posspks ppkcnt;
  %let vars=%mf_getvarlist(&baseds);
  %let vcnt=%sysfunc(countw(&vars));

  %if &vcnt=0 %then %do;
    %put &sysmacroname: &baseds has no variables!  Exiting.;
    %return;
  %end;

  /* get null count and row count */
  %let tmpvar=%mf_getuniquename();
  proc sql noprint;
  create table _data_ as select
    count(*) as &tmpvar
  %do i=1 %to &vcnt;
    %let var=%scan(&vars,&i);
    ,sum(case when &var is missing then 1 else 0 end) as &var
  %end;
    from &baseds;

  /* transpose table and scan for not null cols */
  proc transpose;
  data _null_;
    set &syslast end=last;
    length vars $32767;
    retain vars ;
    if _name_="&tmpvar" then call symputx('rows',col1,'l');
    else if col1=0 then vars=catx(' ',vars,_name_);
    if last then call symputx('posspks',vars,'l');
  run;

  %let ppkcnt=%sysfunc(countw(&posspks));
  %if &ppkcnt=0 %then %do;
    %put &sysmacroname: &baseds has no non-missing variables!  Exiting.;
    %return;
  %end;

  proc sort data=&baseds(keep=&posspks) out=_data_ noduprec;
    by _all_;
  run;
  %local pkds; %let pkds=&syslast;

  %if &rows > %mf_nobs(&pkds) %then %do;
    %put &sysmacroname: &baseds has no combination of unique records! Exiting.;
    %return;
  %end;

  /* now check cardinality */
  proc sql noprint;
  create table _data_ as select
  %do i=1 %to &ppkcnt;
    %let var=%scan(&posspks,&i);
    count(distinct &var) as &var
    %if &i<&ppkcnt %then ,;
  %end;
    from &pkds;

  /* transpose and sort by cardinality */
  proc transpose;
  proc sort; by descending col1;
  run;

  /* create initial PK list and re-order posspks list */
  data &outds(keep=pkguesses);
    length pkguesses $5000 vars $5000;
    set &syslast end=last;
    retain vars ;
    vars=catx(' ',vars,_name_);
    if col1=&rows then do;
      pkguesses=_name_;
      output;
    end;
    if last then call symputx('posspks',vars,'l');
  run;

  %if %mf_nobs(&outds) ge &max_guesses %then %do;
    %put &sysmacroname: %mf_nobs(&outds) possible primary key values found;
    %return;
  %end;

  %if &ppkcnt=1 %then %do;
    %put &sysmacroname: No more PK guess possible;
    %return;
  %end;

  /* begin scanning for uniques on pairs of PKs */
  %let tmpds=%mf_getuniquename();
  %local lev1 lev2;
  %do i=1 %to &ppkcnt;
    %let lev1=%scan(&posspks,&i);
    %do j=2 %to &ppkcnt;
      %let lev2=%scan(&posspks,&j);
      %if &lev1 ne &lev2 %then %do;
        /* check for two level uniqueness */
        proc sort data=&pkds(keep=&lev1 &lev2) out=&tmpds noduprec;
          by _all_;
        run;
        %if %mf_nobs(&tmpds)=&rows %then %do;
          proc sql;
          insert into &outds values("&lev1 &lev2");
          %if %mf_nobs(&outds) ge &max_guesses %then %do;
            %put &sysmacroname: Max PKs reached at Level 2 for &baseds;
            %return;
          %end;
        %end;
      %end;
    %end;
  %end;

  %if &ppkcnt=2 %then %do;
    %put &sysmacroname: No more PK guess possible;
    %return;
  %end;

  /* begin scanning for uniques on PK triplets */
  %local lev3;
  %do i=1 %to &ppkcnt;
    %let lev1=%scan(&posspks,&i);
    %do j=2 %to &ppkcnt;
      %let lev2=%scan(&posspks,&j);
      %if &lev1 ne &lev2 %then %do k=3 %to &ppkcnt;
        %let lev3=%scan(&posspks,&k);
        %if &lev1 ne &lev3 and &lev2 ne &lev3 %then %do;
          /* check for three level uniqueness */
          proc sort data=&pkds(keep=&lev1 &lev2 &lev3) out=&tmpds noduprec;
            by _all_;
          run;
          %if %mf_nobs(&tmpds)=&rows %then %do;
            proc sql;
            insert into &outds values("&lev1 &lev2 &lev3");
            %if %mf_nobs(&outds) ge &max_guesses %then %do;
              %put &sysmacroname: Max PKs reached at Level 3 for &baseds;
              %return;
            %end;
          %end;
        %end;
      %end;
    %end;
  %end;

  %if &ppkcnt=3 %then %do;
    %put &sysmacroname: No more PK guess possible;
    %return;
  %end;

  /* scan for uniques on up to 4 PK fields */
  %local lev4;
  %do i=1 %to &ppkcnt;
    %let lev1=%scan(&posspks,&i);
    %do j=2 %to &ppkcnt;
      %let lev2=%scan(&posspks,&j);
      %if &lev1 ne &lev2 %then %do k=3 %to &ppkcnt;
        %let lev3=%scan(&posspks,&k);
        %if &lev1 ne &lev3 and &lev2 ne &lev3 %then %do l=4 %to &ppkcnt;
          %let lev4=%scan(&posspks,&l);
          %if &lev1 ne &lev4 and &lev2 ne &lev4 and &lev3 ne &lev4 %then %do;
            /* check for four level uniqueness */
            proc sort data=&pkds(keep=&lev1 &lev2 &lev3 &lev4)
                out=&tmpds noduprec;
              by _all_;
            run;
            %if %mf_nobs(&tmpds)=&rows %then %do;
              proc sql;
              insert into &outds values("&lev1 &lev2 &lev3 &lev4");
              %if %mf_nobs(&outds) ge &max_guesses %then %do;
                %put &sysmacroname: Max PKs reached at Level 4 for &baseds;
                %return;
              %end;
            %end;
          %end;
        %end;
      %end;
    %end;
  %end;

  %if &ppkcnt=4 %then %do;
    %put &sysmacroname: No more PK guess possible;
    %return;
  %end;

  /* scan for uniques on up to 4 PK fields */
  %local lev5 m;
  %do i=1 %to &ppkcnt;
    %let lev1=%scan(&posspks,&i);
    %do j=2 %to &ppkcnt;
      %let lev2=%scan(&posspks,&j);
      %if &lev1 ne &lev2 %then %do k=3 %to &ppkcnt;
        %let lev3=%scan(&posspks,&k);
        %if &lev1 ne &lev3 and &lev2 ne &lev3 %then %do l=4 %to &ppkcnt;
          %let lev4=%scan(&posspks,&l);
          %if &lev1 ne &lev4 and &lev2 ne &lev4 and &lev3 ne &lev4 %then
          %do m=5 %to &ppkcnt;
            %let lev5=%scan(&posspks,&m);
            %if &lev1 ne &lev5 & &lev2 ne &lev5 & &lev3 ne &lev5 & &lev4 ne &lev5 %then %do;
              /* check for four level uniqueness */
              proc sort data=&pkds(keep=&lev1 &lev2 &lev3 &lev4 &lev5)
                  out=&tmpds noduprec;
                by _all_;
              run;
              %if %mf_nobs(&tmpds)=&rows %then %do;
                proc sql;
                insert into &outds values("&lev1 &lev2 &lev3 &lev4 &lev5");
                %if %mf_nobs(&outds) ge &max_guesses %then %do;
                  %put &sysmacroname: Max PKs reached at Level 5 for &baseds;
                  %return;
                %end;
              %end;
            %end;
          %end;
        %end;
      %end;
    %end;
  %end;

  %if &ppkcnt=5 %then %do;
    %put &sysmacroname: No more PK guess possible;
    %return;
  %end;

  /* scan for uniques on up to 4 PK fields */
  %local lev6 n;
  %do i=1 %to &ppkcnt;
    %let lev1=%scan(&posspks,&i);
    %do j=2 %to &ppkcnt;
      %let lev2=%scan(&posspks,&j);
      %if &lev1 ne &lev2 %then %do k=3 %to &ppkcnt;
        %let lev3=%scan(&posspks,&k);
        %if &lev1 ne &lev3 and &lev2 ne &lev3 %then %do l=4 %to &ppkcnt;
          %let lev4=%scan(&posspks,&l);
          %if &lev1 ne &lev4 and &lev2 ne &lev4 and &lev3 ne &lev4 %then
          %do m=5 %to &ppkcnt;
            %let lev5=%scan(&posspks,&m);
            %if &lev1 ne &lev5 & &lev2 ne &lev5 & &lev3 ne &lev5 & &lev4 ne &lev5 %then
            %do n=6 %to &ppkcnt;
              %let lev6=%scan(&posspks,&n);
              %if &lev1 ne &lev6 & &lev2 ne &lev6 & &lev3 ne &lev6
              & &lev4 ne &lev6 & &lev5 ne &lev6 %then
              %do;
                /* check for four level uniqueness */
                proc sort data=&pkds(keep=&lev1 &lev2 &lev3 &lev4 &lev5 &lev6)
                  out=&tmpds noduprec;
                  by _all_;
                run;
                %if %mf_nobs(&tmpds)=&rows %then %do;
                  proc sql;
                  insert into &outds
                    values("&lev1 &lev2 &lev3 &lev4 &lev5 &lev6");
                  %if %mf_nobs(&outds) ge &max_guesses %then %do;
                    %put &sysmacroname: Max PKs reached at Level 6 for &baseds;
                    %return;
                  %end;
                %end;
              %end;
            %end;
          %end;
        %end;
      %end;
    %end;
  %end;

  %if &ppkcnt=6 %then %do;
    %put &sysmacroname: No more PK guess possible;
    %return;
  %end;

%mend mp_guesspk;/**
  @file
  @brief Returns a unique hash for a dataset
  @details Ignores metadata attributes, used only to hash values. Compared
  datasets must be in the same order.

      %mp_hashdataset(sashelp.class,outds=myhash)

      data _null_;
        set work.myhash;
        put hashkey=;
      run;

  ![sas md5 hash dataset log results](https://i.imgur.com/MqF98vk.png)

  <h4> SAS Macros </h4>
  @li mf_getattrn.sas
  @li mf_getuniquename.sas
  @li mf_getvarlist.sas
  @li mf_getvartype.sas

  @param [in] libds dataset to hash
  @param [in] salt= Provide a salt (could be, for instance, the dataset name)
  @param [in] iftrue= A condition under which the macro should be executed.
  @param [out] outds= (work.mf_hashdataset) The output dataset to create. This
  will contain one column (hashkey) with one observation (a hex32.
  representation of the input hash)
  |hashkey:$32.|
  |---|
  |28ABC74ABFC45F50794237BA5566E6CA|

  @version 9.2
  @author Allan Bowe
**/

%macro mp_hashdataset(
  libds,
  outds=,
  salt=,
  iftrue=%str(1=1)
)/*/STORE SOURCE*/;

  %if not(%eval(%unquote(&iftrue))) %then %return;

  %if %mf_getattrn(&libds,NLOBS)=0 %then %do;
    %put %str(WARN)ING: Dataset &libds is empty, or is not a dataset;
  %end;
  %else %if %mf_getattrn(&libds,NLOBS)<0 %then %do;
    %put %str(ERR)OR: Dataset &libds is not a dataset;
  %end;
  %else %do;
    %local keyvar /* roll up the md5 */
      prevkeyvar /* retain prev record md5 */
      lastvar /* last var in input ds */
      varlist var i;
    /* avoid naming conflict for hash key vars */
    %let keyvar=%mf_getuniquename();
    %let prevkeyvar=%mf_getuniquename();
    %let lastvar=%mf_getuniquename();
    %let varlist=%mf_getvarlist(&libds);
    data &outds(rename=(&keyvar=hashkey) keep=&keyvar);
      length &prevkeyvar &keyvar $32;
      retain &prevkeyvar "%sysfunc(md5(%str(&salt)),$hex32.)";
      set &libds end=&lastvar;
      /* hash should include previous row */
      &keyvar=put(md5(&prevkeyvar
      /* loop every column, hashing every individual value */
    %do i=1 %to %sysfunc(countw(&varlist));
      %let var=%scan(&varlist,&i,%str( ));
      %if %mf_getvartype(&libds,&var)=C %then %do;
          !!put(md5(trim(&var)),$hex32.)
      %end;
      %else %do;
          !!put(md5(trim(put(&var*1,binary64.))),$hex32.)
      %end;
    %end;
      ),$hex32.);
      &prevkeyvar=&keyvar;
      if &lastvar then output;
    run;
  %end;
%mend mp_hashdataset;/**
  @file
  @brief Performs a wrapped \%include
  @details This macro wrapper is necessary if you need your included code to
  know that it is being \%included.

  If you are using %include in a regular program, you could make use of the
  following macro variables:

  @li SYSINCLUDEFILEDEVICE
  @li SYSINCLUDEFILEDIR
  @li SYSINCLUDEFILEFILEREF
  @li SYSINCLUDEFILENAME

  However these variables are NOT available inside a macro, as documented here:
https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/mcrolref/n1j5tcc0n2xczyn1kg1o0606gsv9.htm

  This macro can be used in place of the %include statement, and will insert
  the following (equivalent) global variables:

  @li _SYSINCLUDEFILEDEVICE
  @li _SYSINCLUDEFILEDIR
  @li _SYSINCLUDEFILEFILEREF
  @li _SYSINCLUDEFILENAME

  These can be used whenever testing _within a macro_.  Outside of the macro,
  the regular automatic variables will still be available (thanks to a
  concatenated file list in the include statement).

  Example usage:

      filename example temp;
      data _null_;
        file example;
        put '%macro test();';
        put '%put &=_SYSINCLUDEFILEFILEREF;';
        put '%put &=SYSINCLUDEFILEFILEREF;';
        put '%mend; %test()';
        put '%put &=SYSINCLUDEFILEFILEREF;';
      run;
      %mp_include(example)

  @param [in] fileref The fileref of the file to be included. Must be provided.
  @param [in] prefix= (_) The prefix to apply to the global variables.
  @param [in] opts= (SOURCE2) The options to apply to the %inc statement
  @param [in] errds= (work.mp_abort_errds) There is no clean way to end a
    process within a %include called within a macro.  Furthermore, there is no
    way to test if a macro is called within a %include.  To handle this
    particular scenario, the %mp_abort() macro will test for the existence of
    the `_SYSINCLUDEFILEDEVICE` variable and return the outputs (msg,mac) inside
    this dataset.
    It will then run an abort cancel FILE to stop the include running, and pass
    the dataset back.
    NOTE - it is NOT possible to read this dataset as part of _this_ macro -
    when running abort cancel FILE, ALL macros are closed, so instead it is
    necessary to invoke "%mp_abort(mode=INCLUDE)" OUTSIDE of any macro wrappers.


  @version 9.4
  @author Allan Bowe

  <h4> SAS Macros </h4>
  @li mf_getuniquefileref.sas
  @li mp_abort.sas

**/

%macro mp_include(fileref
  ,prefix=_
  ,opts=SOURCE2
  ,errds=work.mp_abort_errds
)/*/STORE SOURCE*/;

/* prepare precode */
%local tempref;
%let tempref=%mf_getuniquefileref();
data _null_;
  file &tempref;
  set sashelp.vextfl(where=(fileref="%upcase(&fileref)"));
  put '%let _SYSINCLUDEFILEDEVICE=' xengine ';';
  name=scan(xpath,-1,'/\');
  put '%let _SYSINCLUDEFILENAME=' name ';';
  path=subpad(xpath,1,length(xpath)-length(name)-1);
  put '%let _SYSINCLUDEFILEDIR=' path ';';
  put '%let _SYSINCLUDEFILEFILEREF=' "&fileref;";
run;

/* prepare the errds */
data &errds;
  length msg mac $1000;
  call missing(msg,mac);
  iftrue='1=0';
run;

/* include the include */
%inc &tempref &fileref/&opts;

%mp_abort(iftrue= (&syscc ne 0)
  ,mac=%str(&_SYSINCLUDEFILEDIR/&_SYSINCLUDEFILENAME)
  ,msg=%str(syscc=&syscc after executing &_SYSINCLUDEFILENAME)
)

filename &tempref clear;

%mend mp_include;/**
  @file
  @brief Initialise session with useful settings and variables
  @details Implements a "strict" set of SAS options for use in defensive
    programming.  Highly recommended, if you want your code to run on some
    other machine.

    This macro is recommended to be compiled and invoked in the `initProgram`
    for SASjs [Jobs](https://cli.sasjs.io/sasjsconfig.html#jobConfig_initProgram
    ), [Services](
    https://cli.sasjs.io/sasjsconfig.html#serviceConfig_initProgram) and [Tests]
    (https://cli.sasjs.io/sasjsconfig.html#testConfig_initProgram).

    For non SASjs projects, you could invoke in the autoexec, or in your own
    solution initialisation macro.


    If you have a good idea for another useful option, setting, or global
    variable - feel free to [raise an issue](
    https://github.com/sasjs/core/issues/new)!

    All global variables are prefixed with "SASJS" (unless modified with the
    prefix parameter).

  @param [in] prefix= (SASJS) The prefix to apply to the global macro variables


  @version 9.2
  @author Allan Bowe

**/

%macro mp_init(prefix=SASJS
)/*/STORE SOURCE*/;

  %global
    &prefix._INIT_NUM   /* initialisation time as numeric                   */
    &prefix._INIT_DTTM  /* initialisation time in E8601DT26.6 format        */
    &prefix.WORK        /* avoid typing %sysfunc(pathname(work)) every time */
  ;
  %if %eval(&&&prefix._INIT_NUM>0) %then %return;  /* only run once */

  data _null_;
    dttm=datetime();
    call symputx("&prefix._init_num",dttm,'g');
    call symputx("&prefix._init_dttm",put(dttm,E8601DT26.6),'g');
    call symputx("&prefix.work",pathname('WORK'),'g');
  run;

  options
    noautocorrect           /* disallow misspelled procedure names            */
    compress=CHAR           /* default is none so ensure we have something!   */
    datastmtchk=ALLKEYWORDS /* protection from overwriting input datasets     */
    %str(err)orcheck=STRICT /* catch errs in libname/filename statements      */
    fmterr                  /* ensure err when a format cannot be found       */
    mergenoby=%str(ERR)OR   /* throw err when a merge has no BY variables     */
    missing=.               /* changing this can cause hard to detect errs    */
    noquotelenmax           /* avoid warnings for long strings                */
    noreplace               /* avoid overwriting permanent datasets           */
    ps=max                  /* reduce log size slightly                       */
    ls=max                  /* reduce log even more and avoid word truncation */
    validmemname=COMPATIBLE /* avoid special characters etc in table names    */
    validvarname=V7         /* avoid special characters etc in variable names */
    varinitchk=%str(ERR)OR  /* avoid data mistakes from variable name typos   */
    varlenchk=%str(ERR)OR   /* fail hard if truncation (data loss) can result */
  ;

%mend mp_init;/**
  @file mp_jsonout.sas
  @brief Writes JSON in SASjs format to a fileref
  @details PROC JSON is faster but will produce errs like the ones below if
  special chars are encountered.

  > (ERR)OR: Some code points did not transcode.

  > An object or array close is not valid at this point in the JSON text.

  > Date value out of range

  If this happens, try running with ENGINE=DATASTEP.

  Usage:

        filename tmp temp;
        data class; set sashelp.class;run;

        %mp_jsonout(OPEN,jref=tmp)
        %mp_jsonout(OBJ,class,jref=tmp)
        %mp_jsonout(CLOSE,jref=tmp)

        data _null_;
        infile tmp;
        input;list;
        run;

  If you are building web apps with SAS then you are strongly encouraged to use
  the mX_createwebservice macros in combination with the
  [sasjs adapter](https://github.com/sasjs/adapter).
  For more information see https://sasjs.io

  @param action Valid values:
    @li OPEN - opens the JSON
    @li OBJ - sends a table with each row as an object
    @li ARR - sends a table with each row in an array
    @li CLOSE - closes the JSON

  @param ds the dataset to send.  Must be a work table.
  @param jref= the fileref to which to send the JSON
  @param dslabel= the name to give the table in the exported JSON
  @param fmt= Whether to keep or strip formats from the table
  @param engine= Which engine to use to send the JSON, valid options are:
    @li PROCJSON (default)
    @li DATASTEP (more reliable when data has non standard characters)

  @param dbg= DEPRECATED - was used to conditionally add PRETTY to
    proc json but this can cause line truncation in large files.

  <h4> Related Macros <h4>
  @li mp_ds2fmtds.sas

  @version 9.2
  @author Allan Bowe
  @source https://github.com/sasjs/core

**/

%macro mp_jsonout(action,ds,jref=_webout,dslabel=,fmt=Y,engine=DATASTEP,dbg=0
)/*/STORE SOURCE*/;
%put output location=&jref;
%if &action=OPEN %then %do;
  options nobomfile;
  data _null_;file &jref encoding='utf-8' ;
    put '{"PROCESSED_DTTM" : "' "%sysfunc(datetime(),E8601DT26.6)" '"';
  run;
%end;
%else %if (&action=ARR or &action=OBJ) %then %do;
  options validvarname=upcase;
  data _null_;file &jref mod encoding='utf-8' ;
    put ", ""%lowcase(%sysfunc(coalescec(&dslabel,&ds)))"":";

  %if &engine=PROCJSON %then %do;
    data;run;%let tempds=&syslast;
    proc sql;drop table &tempds;
    data &tempds /view=&tempds;set &ds;
    %if &fmt=N %then format _numeric_ best32.;;
    proc json out=&jref pretty
        %if &action=ARR %then nokeys ;
        ;export &tempds / nosastags fmtnumeric;
    run;
    proc sql;drop view &tempds;
  %end;
  %else %if &engine=DATASTEP %then %do;
    %local cols i tempds;
    %let cols=0;
    %if %sysfunc(exist(&ds)) ne 1 & %sysfunc(exist(&ds,VIEW)) ne 1 %then %do;
      %put &sysmacroname:  &ds NOT FOUND!!!;
      %return;
    %end;
    %if &fmt=Y %then %do;
      %put converting every variable to a formatted variable;
      /* see mp_ds2fmtds.sas for source */
      proc contents noprint data=&ds
        out=_data_(keep=name type length format formatl formatd varnum);
      run;
      proc sort;
        by varnum;
      run;
      %local fmtds;
      %let fmtds=%scan(&syslast,2,.);
      /* prepare formats and varnames */
      data _null_;
        if _n_=1 then call symputx('nobs',nobs,'l');
        set &fmtds end=last nobs=nobs;
        name=upcase(name);
        /* fix formats */
        if type=2 or type=6 then do;
          length fmt $49.;
          if format='' then fmt=cats('$',length,'.');
          else if formatl=0 then fmt=cats(format,'.');
          else fmt=cats(format,formatl,'.');
          newlen=max(formatl,length);
        end;
        else do;
          if format='' then fmt='best.';
          else if formatl=0 then fmt=cats(format,'.');
          else if formatd=0 then fmt=cats(format,formatl,'.');
          else fmt=cats(format,formatl,'.',formatd);
          /* needs to be wide, for datetimes etc */
          newlen=max(length,formatl,24);
        end;
        /* 32 char unique name */
        newname='sasjs'!!substr(cats(put(md5(name),$hex32.)),1,27);

        call symputx(cats('name',_n_),name,'l');
        call symputx(cats('newname',_n_),newname,'l');
        call symputx(cats('len',_n_),newlen,'l');
        call symputx(cats('fmt',_n_),fmt,'l');
        call symputx(cats('type',_n_),type,'l');
      run;
      data &fmtds;
        /* rename on entry */
        set &ds(rename=(
      %local i;
      %do i=1 %to &nobs;
        &&name&i=&&newname&i
      %end;
        ));
      %do i=1 %to &nobs;
        length &&name&i $&&len&i;
        &&name&i=left(put(&&newname&i,&&fmt&i));
        drop &&newname&i;
      %end;
        if _error_ then call symputx('syscc',1012);
      run;
      %let ds=&fmtds;
    %end; /* &fmt=Y */
    data _null_;file &jref mod encoding='utf-8' ;
      put "["; call symputx('cols',0,'l');
    proc sort
      data=sashelp.vcolumn(where=(libname='WORK' & memname="%upcase(&ds)"))
      out=_data_;
      by varnum;

    data _null_;
      set _last_ end=last;
      call symputx(cats('name',_n_),name,'l');
      call symputx(cats('type',_n_),type,'l');
      call symputx(cats('len',_n_),length,'l');
      if last then call symputx('cols',_n_,'l');
    run;

    proc format; /* credit yabwon for special null removal */
      value bart ._ - .z = null
      other = [best.];

    data;run; %let tempds=&syslast; /* temp table for spesh char management */
    proc sql; drop table &tempds;
    data &tempds/view=&tempds;
      attrib _all_ label='';
      %do i=1 %to &cols;
        %if &&type&i=char %then %do;
          length &&name&i $32767;
          format &&name&i $32767.;
        %end;
      %end;
      set &ds;
      format _numeric_ bart.;
    %do i=1 %to &cols;
      %if &&type&i=char %then %do;
        &&name&i='"'!!trim(prxchange('s/"/\"/',-1,
                    prxchange('s/'!!'0A'x!!'/\n/',-1,
                    prxchange('s/'!!'0D'x!!'/\r/',-1,
                    prxchange('s/'!!'09'x!!'/\t/',-1,
                    prxchange('s/\\/\\\\/',-1,&&name&i)
        )))))!!'"';
      %end;
    %end;
    run;
    /* write to temp loc to avoid _webout truncation
      - https://support.sas.com/kb/49/325.html */
    filename _sjs temp lrecl=131068 encoding='utf-8';
    data _null_; file _sjs lrecl=131068 encoding='utf-8' mod ;
      set &tempds;
      if _n_>1 then put "," @; put
      %if &action=ARR %then "[" ; %else "{" ;
      %do i=1 %to &cols;
        %if &i>1 %then  "," ;
        %if &action=OBJ %then """&&name&i"":" ;
        &&name&i
      %end;
      %if &action=ARR %then "]" ; %else "}" ; ;
    proc sql;
    drop view &tempds;
    /* now write the long strings to _webout 1 byte at a time */
    data _null_;
      length filein 8 fileid 8;
      filein = fopen("_sjs",'I',1,'B');
      fileid = fopen("&jref",'A',1,'B');
      rec = '20'x;
      do while(fread(filein)=0);
        rc = fget(filein,rec,1);
        rc = fput(fileid, rec);
        rc =fwrite(fileid);
      end;
      rc = fclose(filein);
      rc = fclose(fileid);
    run;
    filename _sjs clear;
    data _null_; file &jref mod encoding='utf-8' ;
      put "]";
    run;
  %end;
%end;

%else %if &action=CLOSE %then %do;
  data _null_;file &jref encoding='utf-8' mod ;
    put "}";
  run;
%end;
%mend mp_jsonout;
/**
  @file
  @brief Convert all library members to CARDS files
  @details Gets list of members then calls the <code>%mp_ds2cards()</code> macro.
  Usage:

      %mp_lib2cards(lib=sashelp
          , outloc= C:\temp )

  The output will be one cards file in the `outloc` directory per dataset in the
  input `lib` library.  If the `outloc` directory does not exist, it is created.

  To create a single SAS file with the first 1000 records of each table in a
  library you could use this syntax:

      %mp_lib2cards(lib=sashelp
          , outloc= /tmp
          , outfile= myfile.sas
          , maxobs= 1000
      )

  <h4> SAS Macros </h4>
  @li mf_mkdir.sas
  @li mf_trimstr.sas
  @li mp_ds2cards.sas

  @param [in] lib= Library in which to convert all datasets
  @param [out] outloc= Location in which to store output.  Defaults to WORK
    library. No quotes.
  @param [out] outfile= Optional output file NAME - if provided, then will create
  a single output file instead of one file per input table.
  @param [in] maxobs= limit output to the first <code>maxobs</code> observations

  @version 9.2
  @author Allan Bowe
**/

%macro mp_lib2cards(lib=
    ,outloc=%sysfunc(pathname(work)) /* without trailing slash */
    ,maxobs=max
    ,random_sample=NO
    ,outfile=0
)/*/STORE SOURCE*/;

/* Find the tables */
%local x ds memlist;
proc sql noprint;
select distinct lowcase(memname)
  into: memlist
  separated by ' '
  from dictionary.tables
  where upcase(libname)="%upcase(&lib)";

/* trim trailing slash, if provided */
%let outloc=%mf_trimstr(&outloc,/);
%let outloc=%mf_trimstr(&outloc,\);

/* create the output directory */
%mf_mkdir(&outloc)

/* create the cards files */
%do x=1 %to %sysfunc(countw(&memlist));
  %let ds=%scan(&memlist,&x);
  %mp_ds2cards(base_ds=&lib..&ds
    ,maxobs=&maxobs
    ,random_sample=&random_sample
  %if "&outfile" ne "0" %then %do;
    ,append=YES
    ,cards_file="&outloc/&outfile"
  %end;
  %else %do;
    ,append=NO
    ,cards_file="&outloc/&ds..sas"
  %end;
  )
%end;

%mend mp_lib2cards;/**
  @file
  @brief Convert all data in a library to SQL insert statements
  @details Gets list of members then calls the <code>%mp_ds2inserts()</code>
  macro.
  Usage:

      %mp_getddl(sashelp, schema=work, fref=tempref)

      %mp_lib2inserts(sashelp, schema=work, outref=tempref)

      %inc tempref;


  The output will be one file in the outref fileref.


  <h4> SAS Macros </h4>
  @li mp_ds2inserts.sas


  @param [in] lib Library in which to convert all datasets to inserts
  @param [in] flavour= (SAS) The SQL flavour to be applied to the output. Valid
    options:
    @li SAS (default) - suitable for regular proc sql
    @li PGSQL - Used for Postgres databases
  @param [in] maxobs= (max) The max number of observations (per table) to create
  @param [out] outref= Output fileref in which to create the insert statements.
    If it exists, it will be appended to, otherwise it will be created.
  @param [out] schema= (0) The schema of the target database, or the libref.
  @param [in] applydttm= (YES) If YES, any columns using datetime formats will
    be converted to native DB datetime literals

  @version 9.2
  @author Allan Bowe
**/

%macro mp_lib2inserts(lib
    ,flavour=SAS
    ,outref=0
    ,schema=0
    ,maxobs=max
    ,applydttm=YES
)/*/STORE SOURCE*/;

/* Find the tables */
%local x ds memlist;
proc sql noprint;
select distinct lowcase(memname)
  into: memlist
  separated by ' '
  from dictionary.tables
  where upcase(libname)="%upcase(&lib)"
    and memtype='DATA'; /* exclude views */


%let flavour=%upcase(&flavour);
%if &flavour ne SAS and &flavour ne PGSQL %then %do;
  %put %str(WAR)NING:  &flavour is not supported;
  %return;
%end;


/* create the inserts */
%do x=1 %to %sysfunc(countw(&memlist));
  %let ds=%scan(&memlist,&x);
  %mp_ds2inserts(&lib..&ds
    ,outref=&outref
    ,schema=&schema
    ,outds=&ds
    ,flavour=&flavour
    ,maxobs=&maxobs
    ,applydttm=&applydttm
  )
%end;

%mend mp_lib2inserts;/**
  @file
  @brief Mechanism for locking tables to prevent parallel modifications
  @details Uses a control table to enable ANY table to be locked for updates.
  Only useful if every update uses the macro!   Used heavily within
  [Data Controller for SAS](https://datacontroller.io).

  @param [in] action The action to be performed.  Valid values:
    @li LOCK - Sets the lock flag, also confirms if a SAS lock is available
    @li UNLOCK - Unlocks the table
  @param [in] lib= (WORK) The libref of the table to lock.  Should already be
    assigned.
  @param [in] ds= The dataset to lock
  @param [in] ref= A meaningful reference to enable the lock to be traced. Max
    length is 200 characters.
  @param [out] ctl_ds= (0) The control table which controls the actual locking.
    Should already be assigned and available.  The definition is available by
    running mp_coretable.sas as follows:  `mp_coretable(LOCKTABLE)`.

  @param [in] loops= (25) Number of times to check for a lock.
  @param [in] loop_secs= (1) Seconds to wait between each lock attempt

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mp_lockfilecheck.sas
  @li mf_getuser.sas

  <h4> Related Macros </h4>
  @li mp_lockanytable.test.sas

  @version 9.2

**/

%macro mp_lockanytable(
  action
  ,lib= WORK
  ,ds=0
  ,ref=
  ,ctl_ds=0
  ,loops=25
  ,loop_secs=1
  );
data _null_;
  if _n_=1 then putlog "&sysmacroname entry vars:";
  set sashelp.vmacro;
  where scope="&sysmacroname";
  put name '=' value;
run;

%mp_abort(iftrue= (&ds=0 and &action ne MAKETABLE)
  ,mac=&sysmacroname
  ,msg=%str(dataset was not provided)
)
%mp_abort(iftrue= (&ctl_ds=0)
  ,mac=&sysmacroname
  ,msg=%str(Control dataset was not provided)
)

/* set up lib & mac vars */
%let lib=%upcase(&lib);
%let ds=%upcase(&ds);
%let action=%upcase(&action);
%local user x trans msg abortme;
%let user=%mf_getuser();
%let abortme=0;

%mp_abort(iftrue= (&action ne LOCK & &action ne UNLOCK & &action ne MAKETABLE)
  ,mac=&sysmacroname
  ,msg=%str(Invalid action (&action) provided)
)

/* if an err condition exists, exit before we even begin */
%mp_abort(iftrue= (&syscc>0 and &action=LOCK)
  ,mac=&sysmacroname
  ,msg=%str(aborting due to syscc=&syscc on LOCK entry)
)

/* do not bother locking work tables (else may affect all WORK libraries) */
%if (%upcase(&lib)=WORK or %str(&lib)=%str()) & &action ne MAKETABLE %then %do;
  %put NOTE: WORK libraries will not be registered in the locking system.;
  %return;
%end;

/* do not proceed if no observations can be processed */
%mp_abort(iftrue= (%sysfunc(getoption(OBS))=0)
  ,mac=&sysmacroname
  ,msg=%str(options obs = 0. syserrortext=&syserrortext)
)

%if &ACTION=LOCK %then %do;

  /* abort if a SAS lock is already in place, or cannot be applied */
  %mp_lockfilecheck(&lib..&ds)

  /* next, check there is a record for this table */
  %local record_exists_check;
  proc sql noprint;
  select count(*) into: record_exists_check from &ctl_ds
    where LOCK_LIB ="&lib" and LOCK_DS="&ds";
  quit;
  %if &syscc>0 %then %put syscc=&syscc sqlrc=&sqlrc;
  %if &record_exists_check=0 %then %do;
    data _null_;
      putlog "&sysmacroname: adding record to lock table..";
    run;

    data ;
      if 0 then set &ctl_ds;
      LOCK_LIB ="&lib";
      LOCK_DS="&ds";
      LOCK_STATUS_CD='LOCKED';
      LOCK_START_DTTM="%sysfunc(datetime(),E8601DT26.6)"dt;
      LOCK_USER_NM="&user";
      LOCK_PID="&sysjobid";
      LOCK_REF="&ref";
      output;stop;
    run;
    %let trans=&syslast;
    proc append base=&ctl_ds data=&trans;
    run;
  %end;
  /* if record does exist, perform lock attempts */
  %else %do x=1 %to &loops;
    data _null_;
      putlog "&sysmacroname: attempting lock (iteration &x) "@;
      putlog "at %sysfunc(datetime(),datetime19.) ..";
    run;

    proc sql;
    update &ctl_ds
      set LOCK_STATUS_CD='LOCKED'
        , LOCK_START_DTTM="%sysfunc(datetime(),E8601DT26.6)"dt
        , LOCK_USER_NM="&user"
        , LOCK_PID="&sysjobid"
        , LOCK_REF="&ref"
      where LOCK_LIB ="&lib" and LOCK_DS="&ds";
    quit;
    /**
      * NOTE - occasionally SQL server will return an err code (deadlocked
      * transaction).  If so, ignore it, keep calm, and carry on..
      */
    %if &syscc>0 %then %do;
      data _null_;
        putlog 'NOTE-' / 'NOTE-';
        putlog "NOTE- &sysmacroname: Update failed. "@;
        putlog "Resetting err conditions and re-attempting.";
        putlog "NOTE- syscc=&syscc syserr=&syserr sqlrc=&sqlrc";
        putlog 'NOTE-' / 'NOTE-';
      run;
      %let syscc=0;
      %let sqlrc=0;
    %end;

    /* now check if the record was successfully updated */
    %local success_check;
    proc sql noprint;
    select count(*) into: success_check from &ctl_ds
      where LOCK_LIB ="&lib" and LOCK_DS="&ds"
        and LOCK_PID="&sysjobid" and LOCK_STATUS_CD='LOCKED';
    quit;
    %if &success_check=0 %then %do;
      %if &x < &loops %then %do;
        /* pause before next check */
        data _null_;
          putlog 'NOTE-' / 'NOTE-';
          putlog "NOTE- &sysmacroname: table locked, waiting "@;
          putlog "%sysfunc(sleep(&loop_inc)) seconds.. ";
          putlog "NOTE- (iteration &x of &loops)";
          putlog 'NOTE-' / 'NOTE-';
        run;
      %end;
      %else %do;
        %let msg=Unable to lock &lib..&ds via &ctl_ds after &loops attempts.\n
            Please ask your administrator to investigate!;
        %let abortme=1;
      %end;
    %end;
    %else %do;
      data _null_;
        putlog 'NOTE-' / 'NOTE-';
        putlog "NOTE- &sysmacroname: Table &lib..&ds locked at "@;
        putlog " %sysfunc(datetime(),datetime19.) (iteration &x)"@;
        putlog 'NOTE-' / 'NOTE-';
      run;
      %if &syscc>0 %then %do;
        %put setting syscc(&syscc) back to 0;
        %let syscc=0;
      %end;
      %let x=&loops;  /* no more iterations needed */
    %end;
  %end;
%end;
%else %if &ACTION=UNLOCK %then %do;
  %local status;
  proc sql noprint;
  select LOCK_STATUS_CD into: status from &ctl_ds
    where LOCK_LIB ="&lib" and LOCK_DS="&ds";
  quit;
  %if &syscc>0 %then %put syscc=&syscc sqlrc=&sqlrc;
  %if &status=LOCKED %then %do;
    data _null_;
      putlog "&sysmacroname: unlocking &lib..&ds:";
    run;
    proc sql;
    update &ctl_ds
      set LOCK_STATUS_CD='UNLOCKED'
        , LOCK_END_DTTM="%sysfunc(datetime(),E8601DT26.6)"dt
        , LOCK_USER_NM="&user"
        , LOCK_PID="&sysjobid"
        , LOCK_REF="&ref"
      where LOCK_LIB ="&lib" and LOCK_DS="&ds";
    quit;
  %end;
  %else %if &status=UNLOCKED %then %do;
    %put %str(WAR)NING: &lib..&ds is already unlocked!;
  %end;
  %else %do;
    %put NOTE: Unrecognised STATUS_CD (&status) in &ctl_ds;
    %let abortme=1;
  %end;
%end;
%else %do;
  %let msg=lock_anytable given unsupported action (&action);
  %let abortme=1;
%end;

/* catch errs - mp_abort must be called outside of a logic block */
%mp_abort(iftrue=(&abortme=1),
  msg=%superq(msg),
  mac=&sysmacroname
)

%exit_macro:
data _null_;
  put "&sysmacroname: Exit vars: action=&action lib=&lib ds=&ds";
  put " syscc=&syscc sqlrc=&sqlrc syserr=&syserr";
run;
%mend mp_lockanytable;


/**
  @file
  @brief Aborts if a SAS lock file is in place, or if one cannot be applied.
  @details Used in conjuction with the mp_lockanytable macro.
  More info here: https://sasensei.com/flash/24

  Usage:

      data work.test; a=1;run;
      %mp_lockfilecheck(work.test)

  @param [in] libds The libref.dataset for which to check the lock status

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getattrc.sas

  <h4> Related Macros </h4>
  @li mp_lockanytable.sas
  @li mp_lockfilecheck.test.sas

  @version 9.2
**/

%macro mp_lockfilecheck(
  libds
)/*/STORE SOURCE*/;

data _null_;
  if _n_=1 then putlog "&sysmacroname entry vars:";
  set sashelp.vmacro;
  where scope="&sysmacroname";
  put name '=' value;
run;

%mp_abort(iftrue= (&syscc>0)
  ,mac=checklock.sas
  ,msg=Aborting with syscc=&syscc on entry.
)
%mp_abort(iftrue= (&libds=0)
  ,mac=&sysmacroname
  ,msg=%str(libds not provided)
)

%local msg lib ds;
%let lib=%upcase(%scan(&libds,1,.));
%let ds=%upcase(%scan(&libds,2,.));

/* do not proceed if no observations can be processed */
%let msg=options obs = 0. syserrortext=%superq(syserrortext);
%mp_abort(iftrue= (%sysfunc(getoption(OBS))=0)
  ,mac=checklock.sas
  ,msg=%superq(msg)
)

data _null_;
  putlog "Checking engine & member type";
run;
%local engine memtype;
%let memtype=%mf_getattrc(&libds,MTYPE);
%let engine=%mf_getattrc(&libds,ENGINE);

%if &engine ne V9 and &engine ne BASE %then %do;
  data _null_;
    putlog "Lib &lib  is not assigned using BASE engine - uses &engine instead";
    putlog "SAS lock check will not be performed";
  run;
  %return;
%end;
%else %if &memtype ne DATA %then %do;
  %put NOTE: Cannot lock a VIEW!! Memtype=&memtype;
  %return;
%end;

data _null_;
  putlog "Engine = &engine, memtype=&memtype";
  putlog "Attempting lock statement";
run;

lock &libds;

%local abortme;
%let abortme=0;
%if &syscc>0 or &SYSLCKRC ne 0 %then %do;
  %let msg=Unable to apply lock on &libds (SYSLCKRC=&SYSLCKRC syscc=&syscc);
  %put %str(ERR)OR: &sysmacroname: &msg;
  %let abortme=1;
%end;

lock &libds clear;

%mp_abort(iftrue= (&abortme=1)
  ,mac=&sysmacroname
  ,msg=%superq(msg)
)

%mend mp_lockfilecheck;/**
  @file
  @brief Create sample data based on the structure of an empty table
  @details Many SAS projects involve sensitive datasets.  One way to _ensure_
    the data is anonymised, is never to receive it in the first place!  Often
    consultants are provided with empty tables, and expected to create complex
    ETL flows.

    This macro can help by taking an empty table, and populating it with data
    according to the variable types and formats.

    TODO:
      @li Consider dates, datetimes, times, integers etc

  Usage:

      proc sql;
      create table work.example(
        TX_FROM float format=datetime19.,
        DD_TYPE char(16),
        DD_SOURCE char(2048),
        DD_SHORTDESC char(256),
        constraint pk primary key(tx_from, dd_type,dd_source),
        constraint nnn not null(DD_SHORTDESC)
      );
      %mp_makedata(work.example)

  @param [in] libds The empty table (libref.dataset) in which to create data
  @param [out] obs= (500) The maximum number of records to create.  The table
    is sorted with nodup on the primary key, so the actual number of records may
    be lower than this.

  <h4> SAS Macros </h4>
  @li mf_getuniquename.sas
  @li mf_getvarlen.sas
  @li mf_getvarlist.sas
  @li mf_islibds.sas
  @li mf_nobs.sas
  @li mp_getcols.sas
  @li mp_getpk.sas

  <h4> Related Macros </h4>
  @li mp_makedata.test.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_makedata(libds
  ,obs=500
  ,seed=1
)/*/STORE SOURCE*/;

%local ds1 ds2 lib ds pk_fields i col charvars numvars ispk;

%if %mf_islibds(&libds)=0 %then %do;
  %put &sysmacroname: Invalid libds (&libds) - should be library.dataset format;
  %return;
%end;
%else %if %mf_nobs(&libds)>0 %then %do;
  %put &sysmacroname: &libds has data, it will not be recreated;
  %return;
%end;

/* set up temporary vars */
%let ds1=%mf_getuniquename(prefix=mp_makedatads1);
%let ds2=%mf_getuniquename(prefix=mp_makedatads2);
%let lib=%scan(&libds,1,.);
%let ds=%scan(&libds,2,.);

/* grab the primary key vars */
%mp_getpk(&lib,ds=&ds,outds=&ds1)

proc sql noprint;
select coalescec(pk_fields,'_all_') into: pk_fields from &ds1;

data &ds2;
  if 0 then set &libds;
  do _n_=1 to &obs;
    %let charvars=%mf_getvarlist(&libds,typefilter=C);
    %if &charvars ^= %then %do i=1 %to %sysfunc(countw(&charvars));
      %let col=%scan(&charvars,&i);
      /* create random value based on observation number and colum length */
      &col=repeat(put(md5(cats(_n_)),$hex32.),%mf_getvarlen(&libds,&col)/32);
    %end;

    %let numvars=%mf_getvarlist(&libds,typefilter=N);
    %if &numvars ^= %then %do i=1 %to %sysfunc(countw(&numvars));
      %let col=%scan(&numvars,&i);
      &col=_n_;
    %end;
    output;
  end;
  stop;
run;
proc sort data=&ds2 nodupkey;
  by &pk_fields;
run;

proc append base=&libds data=&ds2;
run;

proc sql;
drop table &ds1, &ds2;

%mend mp_makedata;/**
  @file
  @brief Logs the time the macro was executed in a control dataset.
  @details If the dataset does not exist, it is created.  Usage:

    %mp_perflog(started)
    %mp_perflog()
    %mp_perflog(startanew,libds=work.newdataset)
    %mp_perflog(finished,libds=work.newdataset)
    %mp_perflog(finished)


  @param label Provide label to go into the control dataset
  @param libds= Provide a dataset in which to store performance stats.  Default
              name is <code>work.mp_perflog</code>;

  @version 9.2
  @author Allan Bowe
  @source https://github.com/sasjs/core

**/

%macro mp_perflog(label,libds=work.mp_perflog
)/*/STORE SOURCE*/;

  %if not (%mf_existds(&libds)) %then %do;
    data &libds;
      length sysjobid $10 label $256 dttm 8.;
      format dttm datetime19.3;
      call missing(of _all_);
      stop;
    run;
  %end;

  proc sql;
    insert into &libds
      set sysjobid="&sysjobid"
        ,label=symget('label')
        ,dttm=%sysfunc(datetime());
  quit;

%mend mp_perflog;/**
  @file
  @brief Enables previous observations to be re-instated
  @details Remembers the last X observations by storing them in a hash table.
  Is a convenience over the use of lag() or retain, when an entire observation
  needs to be restored.

  This macro will also restore automatic variables (such as _n_ and _error_).

  Example Usage:

      data example;
        set sashelp.class;
        calc_var=_n_*3;
        %* initialise hash and save from PDV ;
        %mp_prevobs(INIT,history=2)
        if _n_ =10 then do;
          %* fetch previous but 1 record;
          %mp_prevobs(FETCH,-2)
          put _n_= name= age= calc_var=;
          %* fetch previous record;
          %mp_prevobs(FETCH,-1)
          put _n_= name= age= calc_var=;
          %* reinstate current record ;
          %mp_prevobs(FETCH,0)
          put _n_= name= age= calc_var=;
        end;
      run;

  Result:

  <img src="https://imgur.com/PSjHoET.png" alt="mp_prevobs sas" width="400"/>

  Credit is made to `data _null_` for authoring this very helpful paper:
  https://www.lexjansen.com/pharmasug/2008/cc/CC08.pdf

  @param action Either FETCH a current or previous record, or INITialise.
  @param record The relative (to current) position of the previous observation
    to return.
  @param history= The number of records to retain in the hash table. Default=5
  @param prefix= the prefix to give to the variables used to store the hash name
    and index. Default=mp_prevobs

  @version 9.2
  @author Allan Bowe

**/

%macro mp_prevobs(action,record,history=5,prefix=mp_prevobs
)/*/STORE SOURCE*/;
%let action=%upcase(&action);
%let prefix=%upcase(&prefix);
%let record=%eval((&record+0) * -1);

%if &action=INIT %then %do;

  if _n_ eq 1 then do;
    attrib &prefix._VAR length=$64;
    dcl hash &prefix._HASH(ordered:'Y');
    &prefix._KEY=0;
    &prefix._HASH.defineKey("&prefix._KEY");
    do while(1);
      call vnext(&prefix._VAR);
      if &prefix._VAR='' then leave;
      if &prefix._VAR eq "&prefix._VAR" then continue;
      else if &prefix._VAR eq "&prefix._KEY" then continue;
      &prefix._HASH.defineData(&prefix._VAR);
    end;
    &prefix._HASH.defineDone();
  end;
  /* this part has to happen before FETCHing */
  &prefix._KEY+1;
  &prefix._rc=&prefix._HASH.add();
  if &prefix._rc then putlog 'adding' &prefix._rc=;
  %if &history>0 %then %do;
    if &prefix._key>&history+1 then
      &prefix._HASH.remove(key: &prefix._KEY - &history - 1);
    if &prefix._rc then putlog 'removing' &prefix._rc=;
  %end;
%end;
%else %if &action=FETCH %then %do;
  if &record>&prefix._key then putlog "Not enough records in &Prefix._hash yet";
  else &prefix._rc=&prefix._HASH.find(key: &prefix._KEY - &record);
  if &prefix._rc then putlog &prefix._rc= " when fetching " &prefix._KEY=
    "with record &record and " _n_=;
%end;

%mend mp_prevobs;/**
  @file
  @brief Returns all children from a hierarchy table for a specified parent
  @details Where data stores hierarchies in a simple parent / child mapping,
    it is not always straightforward to extract all the children for a
    particular parent.  This problem is known as a recursive self join.  This
    macro will extract all the descendents for a parent.
  Usage:

      data have;
        p=1;c=2;output;
        p=2;c=3;output;
        p=2;c=4;output;
        p=3;c=5;output;
        p=6;c=7;output;
        p=8;c=9;output;
      run;

      %mp_recursivejoin(base_ds=have
        ,outds=want
        ,matchval=1
        ,parentvar=p
        ,childvar=c
        )

  @param base_ds= base table containing hierarchy (not modified)
  @param outds= the output dataset to create with the generated hierarchy
  @param matchval= the ultimate parent from which to filter
  @param parentvar= name of the parent variable
  @param childvar= name of the child variable (should be same type as parent)
  @param mdebug= set to 1 to prevent temp tables being dropped


  @returns outds contains the following variables:
    - level (0 = top level)
    - &parentvar
    - &childvar (null if none found)

  @version 9.2
  @author Allan Bowe

**/

%macro mp_recursivejoin(base_ds=
    ,outds=
    ,matchval=
    ,parentvar=
    ,childvar=
    ,iter= /* reserved for internal / recursive use by the macro itself */
    ,maxiter=500 /* avoid infinite loop */
    ,mDebug=0);

%if &iter= %then %do;
  proc sql;
  create table &outds as
    select 0 as level,&parentvar, &childvar
    from &base_ds
    where &parentvar=&matchval;
  %if &sqlobs.=0 %then %do;
    %put NOTE: &sysmacroname: No match for &parentvar=&matchval;
    %return;
  %end;
  %let iter=1;
%end;
%else %if &iter>&maxiter %then %return;

proc sql;
create table _data_ as
  select &iter as level
    ,curr.&childvar as &parentvar
    ,base_ds.&childvar as &childvar
  from &outds curr
  left join &base_ds base_ds
  on  curr.&childvar=base_ds.&parentvar
  where curr.level=%eval(&iter.-1)
    & curr.&childvar is not null;
%local append_ds; %let append_ds=&syslast;
%local obs; %let obs=&sqlobs;
insert into &outds select distinct * from &append_ds;
%if &mdebug=0 %then drop table &append_ds;;

%if &obs %then %do;
  %mp_recursivejoin(iter=%eval(&iter.+1)
    ,outds=&outds,parentvar=&parentvar
    ,childvar=&childvar
    ,base_ds=&base_ds
    )
%end;

%mend mp_recursivejoin;
/**
  @file
  @brief Reset when an err condition occurs
  @details When building apps, sometimes an operation must be attempted that
  can cause an err condition.  There is no try catch in SAS! So the err state
  must be caught and reset.

  This macro attempts to do that reset.

  @version 9.2
  @author Allan Bowe

**/

%macro mp_reseterror(
)/*/STORE SOURCE*/;

options obs=max replace nosyntaxcheck;
%let syscc=0;

%if "&sysprocessmode " = "SAS Stored Process Server " %then %do;
  data _null_;
    rc=stpsrvset('program error', 0);
  run;
%end;

%mend mp_reseterror;/**
  @file
  @brief Reset an option to original value
  @details Inspired by the SAS Jedi -
https://blogs.sas.com/content/sastraining/2012/08/14/jedi-sas-tricks-reset-sas-system-options

  Called as follows:

      options obs=30 ps=max;
      %mp_resetoption(OBS)
      %mp_resetoption(PS)


  @param [in] option the option to reset

  @version 9.2
  @author Allan Bowe

**/

%macro mp_resetoption(option /* the option to reset */
)/*/STORE SOURCE*/;

data _null_;
  length code  $1500;
  startup=getoption("&option",'startupvalue');
  current=getoption("&option");
  if startup ne current then do;
    code =cat('OPTIONS ',getoption("&option",'keyword','startupvalue'),';');
    putlog "NOTE: Resetting system option: " code ;
    call execute(code );
  end;
run;

%mend mp_resetoption;/**
  @file
  @brief Generate and apply retained key values to a staging table
  @details This macro will populate a staging table with a Retained Key based on
  a business key and a base (target) table.

  Definition of retained key ([source](
    http://bukhantsov.org/2012/04/what-is-data-vault/)):

  > The retained key is a key which is mapped to business key one-to-one. In
  > comparison,  the surrogate key includes time and there can be many surrogate
  > keys corresponding to one business key. This explains the name of the key,
  > it is retained with insertion of a new version of a row while surrogate key
  > is increasing.

  This macro is designed to be used as part of a wider load / ETL process (such
  as the one in [Data Controller for SAS](https://datacontroller.io)).

  Specifically, the macro assumes that the base table has already been 'locked'
  (eg with the mp_lockanytable.sas macro) prior to invocation.  Also, several
  tables are assumed to exist (names are configurable):

  @li work.staging_table - the staged data, minus the retained key element
  @li permlib.base_table - the target table to be loaded (**not** loaded by this
    macro)
  @li permlib.maxkeytable - optional, used to store load metaadata.
    The definition is available by running mp_coretable.sas as follows:
    `mp_coretable(MAXKEYTABLE)`.
  @li permlib.locktable - Necessary if maxkeytable is being populated. The
    definition is available by running mp_coretable.sas as follows:
    `mp_coretable(LOCKTABLE)`.


  @param [in] base_lib= (WORK) Libref of the base (target) table.
  @param [in] base_dsn= (BASETABLE) Name of the base (target) table.
  @param [in] append_lib= (WORK) Libref of the staging table
  @param [in] append_dsn= (APPENDTABLE) Name of the staging table
  @param [in] retained_key= (DEFAULT_RK) Name of RK to generate (should exist on
    base table)
  @param [in] business_key= (PK1 PK2) Business key against which to generate
    RK values.  Should be unique and not null on the staging table.
  @param [in] check_uniqueness=(NO) Set to yes to perform a uniqueness check.
    Recommended if there is a chance that the staging data is not unique on the
    business key.
  @param [in] maxkeytable= (0) Provide a maxkeytable libds reference here, to
    store load metadata (maxkey val, load time).  Set to zero if metadata is not
    required, eg, when preparing a 'dummy' load. Structure is described above.
    See below for sample data.
    |KEYTABLE:$32.|KEYCOLUMN:$32.|MAX_KEY:best.|PROCESSED_DTTM:E8601DT26.6|
    |---|---|---|---|
    |`DC487173.MPE_SELECTBOX `|`SELECTBOX_RK `|`55 `|`1950427787.8 `|
    |`DC487173.MPE_FILTERANYTABLE `|`filter_rk `|`14 `|`1951053886.8 `|
  @param [in] locktable= (0) If updating the maxkeytable, provide the libds
    reference to the lock table (per mp_lockanytable.sas macro)
  @param [in] filter_str= Apply a filter - useful for SCD2 or BITEMPORAL loads.
    Example: `filter_str=%str( (where=( &now < &tech_to)) )`
  @param [out] outds= (WORK.APPEND) Output table (staging table + retained key)

  <h4> SAS Macros </h4>
  @li mf_existvar.sas
  @li mf_getquotedstr.sas
  @li mf_getuniquename.sas
  @li mf_nobs.sas
  @li mp_abort.sas
  @li mp_lockanytable.sas

  <h4> Related Macros </h4>
  @li mp_filterstore.sas
  @li mp_retainedkey.test.sas

  @version 9.2

**/

%macro mp_retainedkey(
  base_lib=WORK
  ,base_dsn=BASETABLE
  ,append_lib=WORK
  ,append_dsn=APPENDTABLE
  ,retained_key=DEFAULT_RK
  ,business_key= PK1 PK2
  ,check_uniqueness=NO
  ,maxkeytable=0
  ,locktable=0
  ,outds=WORK.APPEND
  ,filter_str=
);
%put &sysmacroname entry vars:;
%put _local_;

%local base_libds app_libds key_field check maxkey idx_pk newkey_cnt iserr
  msg x tempds1 tempds2 comma_pk appnobs checknobs dropvar tempvar idx_val;
%let base_libds=%upcase(&base_lib..&base_dsn);
%let app_libds=%upcase(&append_lib..&append_dsn);
%let tempds1=%mf_getuniquename();
%let tempds2=%mf_getuniquename();
%let comma_pk=%mf_getquotedstr(in_str=%str(&business_key),dlm=%str(,),quote=);
%let outds=%sysfunc(ifc(%index(&outds,.)=0,work.&outds,&outds));
/* validation checks */
%let iserr=0;
%if &syscc>0 %then %do;
  %let iserr=1;
  %let msg=%str(SYSCC=&syscc on macro entry);
%end;
%else %if %sysfunc(exist(&base_libds))=0 %then %do;
  %let iserr=1;
  %let msg=%str(Base LIBDS (&base_libds) expected but NOT FOUND);
%end;
%else %if %sysfunc(exist(&app_libds))=0 %then %do;
  %let iserr=1;
  %let msg=%str(Append LIBDS (&app_libds) expected but NOT FOUND);
%end;
%else %if &maxkeytable ne 0 and %sysfunc(exist(&maxkeytable))=0  %then %do;
  %let iserr=1;
  %let msg=%str(Maxkeytable (&maxkeytable) expected but NOT FOUND);
%end;
%else %if &maxkeytable ne 0 and %sysfunc(exist(&locktable))=0  %then %do;
  %let iserr=1;
  %let msg=%str(Locktable (&locktable) expected but NOT FOUND);
%end;
%else %if %length(&business_key)=0 %then %do;
  %let iserr=1;
  %let msg=%str(Business key (&business_key) expected but NOT FOUND);
%end;

%do x=1 %to %sysfunc(countw(&business_key));
  /* check business key values exist */
  %let key_field=%scan(&business_key,&x,%str( ));
  %if not %mf_existvar(&app_libds,&key_field) %then %do;
    %let iserr=1;
    %let msg=Business key (&key_field) not found on &app_libds!;
    %goto err;
  %end;
  %else %if not %mf_existvar(&base_libds,&key_field) %then %do;
    %let iserr=1;
    %let msg=Business key (&key_field) not found on &base_libds!;
    %goto err;
  %end;
%end;
%err:
%if &iserr=1 %then %do;
  /* err case so first perform an unlock of the base table before exiting */
  %mp_lockanytable(
    UNLOCK,lib=&base_lib,ds=&base_dsn,ref=%superq(msg),ctl_ds=&locktable
  )
%end;
%mp_abort(iftrue=(&iserr=1),mac=mp_retainedkey,msg=%superq(msg))

proc sql noprint;
select sum(max(&retained_key),0) into: maxkey from &base_libds;

/**
  * get base table RK and bus field values for lookup
  */
proc sql noprint;
create table &tempds1 as
  select distinct &comma_pk,&retained_key
  from &base_libds &filter_str
  order by &comma_pk,&retained_key;

%if &check_uniqueness=YES %then %do;
  select count(*) into:checknobs
    from (select distinct &comma_pk from &app_libds);
  select count(*) into: appnobs from &app_libds; /* might be view */
  %if &checknobs ne &appnobs %then %do;
    %let msg=Source table &app_libds is not unique on (&business_key);
    %let iserr=1;
  %end;
%end;
%if &iserr=1 %then %do;
  /* err case so first perform an unlock of the base table before exiting */
  %mp_lockanytable(
    UNLOCK,lib=&base_lib,ds=&base_dsn,ref=%superq(msg),ctl_ds=&locktable
  )
%end;
%mp_abort(iftrue= (&iserr=1),mac=mp_retainedkey,msg=%superq(msg))

%if %mf_existvar(&app_libds,&retained_key)
%then %let dropvar=(drop=&retained_key);

/* prepare interim table with retained key populated for matching keys */
proc sql noprint;
create table &tempds2 as
  select b.&retained_key, a.*
  from &app_libds &dropvar a
  left join &tempds1 b
  on 1
  %do idx_pk=1 %to %sysfunc(countw(&business_key));
    %let idx_val=%scan(&business_key,&idx_pk);
    and a.&idx_val=b.&idx_val
  %end;
  order by &retained_key;

/* identify the number of entries without retained keys (new records) */
select count(*) into: newkey_cnt
  from &tempds2
  where missing(&retained_key);
quit;

/**
  * Update maxkey table if link provided
  */
%if &maxkeytable ne 0 %then %do;
  proc sql noprint;
  select count(*) into: check from &maxkeytable
    where upcase(keytable)="&base_libds";

  %mp_lockanytable(LOCK
    ,lib=%scan(&maxkeytable,1,.)
    ,ds=%scan(&maxkeytable,2,.)
    ,ref=Updating maxkeyvalues with mp_retainedkey
    ,ctl_ds=&locktable
  )
  proc sql;
  %if &check=0 %then %do;
  insert into &maxkeytable
    set keytable="&base_libds"
      ,keycolumn="&retained_key"
      ,max_key=%eval(&maxkey+&newkey_cnt)
      ,processed_dttm="%sysfunc(datetime(),E8601DT26.6)"dt;
  %end;
  %else %do;
  update &maxkeytable
    set max_key=%eval(&maxkey+&newkey_cnt)
      ,processed_dttm="%sysfunc(datetime(),E8601DT26.6)"dt
    where keytable="&base_libds";
  %end;
  %mp_lockanytable(UNLOCK
    ,lib=%scan(&maxkeytable,1,.)
    ,ds=%scan(&maxkeytable,2,.)
    ,ref=Updating maxkeyvalues with maxkey=%eval(&maxkey+&newkey_cnt)
    ,ctl_ds=&locktable
  )
%end;

/* fill in the missing retained key values */
%let tempvar=%mf_getuniquename();
data &outds(drop=&tempvar);
  retain &tempvar %eval(&maxkey+1);
  set &tempds2;
  if &retained_key =. then &retained_key=&tempvar;
  &tempvar=&tempvar+1;
run;

%mend mp_retainedkey;

/**
  @file mp_runddl.sas
  @brief An opinionated way to execute DDL files in SAS.
  @details When delivering projects there should be seperation between the DDL
    used to generate the tables and the sample data used to populate them.

  This macro expects certain folder structure - eg:

    rootlib
    |-- LIBREF1
    |   |__ mytable.ddl
    |   |__ someothertable.ddl
    |-- LIBREF2
    |   |__ table1.ddl
    |   |__ table2.ddl
    |-- LIBREF3
        |__ table3.ddl
        |__ table4.ddl

  Only files with the .ddl suffix are executed.  The parent folder name is used
  as the libref.
  Files should NOT contain the `proc sql` statement - this is to prevent
  statements being executed if there is an err condition.

  Usage:

    %mp_runddl(/some/rootlib)  * execute all libs ;

    %mp_runddl(/some/rootlib, inc=LIBREF1 LIBREF2) * include only these libs;

    %mp_runddl(/some/rootlib, exc=LIBREF3) * same as above ;


  @param path location of the DDL folder structure
  @param inc= list of librefs to include
  @param exc= list of librefs to exclude (takes precedence over inc=)

  @version 9.3
  @author Allan Bowe
  @source https://github.com/sasjs/core

**/

%macro mp_runddl(path, inc=, exc=
)/*/STORE SOURCE*/;



%mend mp_runddl;/**
  @file mp_searchcols.sas
  @brief Searches all columns in a library
  @details
  Scans a set of libraries and creates a dataset containing all source tables
    containing one or more of a particular set of columns

  Usage:

      %mp_searchcols(libs=sashelp work, cols=name sex age)

  @param libs=(SASHELP) Space separated list of libraries to search for columns
  @param cols= Space separated list of column names to search for (not case
    sensitive)
  @param outds=(mp_searchcols) the table to create with the results.  Will have
    one line per table match.
  @param match=(ANY) The match type. Valid values:
    @li ANY - The table contains at least one of the columns
    @li WILD - The table contains a column with a name that partially matches

  @version 9.2
  @author Allan Bowe
**/

%macro mp_searchcols(libs=sashelp
  ,cols=
  ,outds=mp_searchcols
  ,match=ANY
)/*/STORE SOURCE*/;

%put &sysmacroname process began at %sysfunc(datetime(),datetime19.);

/* get the list of tables in the library */
proc sql;
create table _data_ as
  select distinct upcase(libname) as libname
    , upcase(memname) as memname
    , upcase(name) as name
  from dictionary.columns
%if %sysevalf(%superq(libs)=,boolean)=0 %then %do;
  where upcase(libname) in ("IMPOSSIBLE",
  %local x;
  %do x=1 %to %sysfunc(countw(&libs));
    "%upcase(%scan(&libs,&x))"
  %end;
  )
%end;
  order by 1,2,3;

%local tempds;
%let tempds=&syslast;
data &outds;
  set &tempds;
  length cols matchcols $32767;
  cols=upcase(symget('cols'));
  colcount=countw(cols);
  by libname memname name;
  if _n_=1 then do;
    putlog "Searching libs: &libs";
    putlog "Searching cols: " cols;
  end;
  if first.memname then do;
    sumcols=0;
    retain matchcols;
    matchcols='';
  end;
%if &match=ANY %then %do;
  if findw(cols,name,,'spit') then do;
    sumcols+1;
    matchcols=cats(matchcols)!!' '!!cats(name);
  end;
%end;
%else %if &match=WILD %then %do;
  if _n_=1 then do;
    retain wcount;
    wcount=countw(cols);
    drop wcount;
  end;
  do i=1 to wcount;
    length curword $32;
    curword=scan(cols,i,' ');
    drop curword;
    if index(name,cats(curword)) then do;
      sumcols+1;
      matchcols=cats(matchcols)!!' '!!cats(curword);
    end;
  end;
%end;

  if last.memname then do;
    if sumcols>0 then output;
    if sumcols=colcount then putlog "Full Match: " libname memname;
  end;
  keep libname memname sumcols matchcols;
run;

proc sort; by descending sumcols memname libname; run;

proc sql;
drop table &tempds;
%put &sysmacroname process finished at %sysfunc(datetime(),datetime19.);

%mend mp_searchcols;/**
  @file
  @brief Searches all data in a library
  @details
  Scans an entire library and creates a copy of any table
    containing a specific string OR numeric value.  Only
    matching records are written out.
    If both a string and numval are provided, the string
    will take precedence.

  Usage:

      %mp_searchdata(lib=sashelp, string=Jan)
      %mp_searchdata(lib=sashelp, ds=bird, numval=1)
      %mp_searchdata(lib=sashelp, ds=class, string=l,outobs=5)


  Outputs zero or more tables to an MPSEARCH library with specific records.

  @param [in] lib=  The libref to search (should be already assigned)
  @param [in] ds= The dataset to search (leave blank to search entire library)
  @param [in] string= String value to search (case sensitive, can be partial)
  @param [in] numval= Numeric value to search (must be exact)
  @param [out] outloc= (0) Optionally specify the directory in which to
    create the the output datasets with matching rows.  By default it will
    write them to a temporary subdirectory within the WORK folder.
  @param [out] outlib= (MPSEARCH) Assign a different libref to the output
    library containing the matching datasets / records
  @param [in] outobs= set to a positive integer to restrict the number of
    observations
  @param [in] filter_text= (1=1) Add a (valid) filter clause to further filter
    the results.

  <h4> SAS Macros </h4>
  @li mf_getuniquename.sas
  @li mf_getvarlist.sas
  @li mf_getvartype.sas
  @li mf_mkdir.sas
  @li mf_nobs.sas

  @version 9.2
  @author Allan Bowe
**/

%macro mp_searchdata(lib=
  ,ds=
  ,string= /* the query will use a contains (?) operator */
  ,numval= /* numeric must match exactly */
  ,outloc=0
  ,outlib=MPSEARCH
  ,outobs=-1
  ,filter_text=%str(1=1)
)/*/STORE SOURCE*/;

%local table_list table table_num table colnum col start_tm check_tm vars type
  coltype;
%put process began at %sysfunc(datetime(),datetime19.);

%if &syscc ge 4 %then %do;
  %put %str(WAR)NING: SYSCC=&syscc on macro entry;
  %return;
%end;

%if &string = %then %let type=N;
%else %let type=C;

%if "&outloc"="0" %then %do;
  %let outloc=%sysfunc(pathname(work))/%mf_getuniquename();
%end;

%mf_mkdir(&outloc)
libname &outlib "&outloc";

/* get the list of tables in the library */
proc sql noprint;
select distinct memname into: table_list separated by ' '
  from dictionary.tables
  where upcase(libname)="%upcase(&lib)"
%if &ds ne %then %do;
  and upcase(memname)=%upcase("&ds")
%end;
  ;
/* check that we have something to check */
%if %length(&table_list)=0 %then %put library &lib contains no tables!;
/* loop through each table */
%else %do table_num=1 %to %sysfunc(countw(&table_list,%str( )));
  %let table=%scan(&table_list,&table_num,%str( ));
  %let vars=%mf_getvarlist(&lib..&table);
  %if %length(&vars)=0 %then %do;
    %put NO COLUMNS IN &lib..&table!  This will be skipped.;
  %end;
  %else %do;
    %let check_tm=%sysfunc(datetime());
    /* prep input */
    data &outlib..&table;
      set &lib..&table;
      where %unquote(&filter_text) and ( 0
    /* loop through columns */
    %do colnum=1 %to %sysfunc(countw(&vars,%str( )));
      %let col=%scan(&vars,&colnum,%str( ));
      %let coltype=%mf_getvartype(&lib..&table,&col);
      %if &type=C and &coltype=C %then %do;
        /* if a char column, see if it contains the string */
        or ("&col"n ? "&string")
      %end;
      %else %if &type=N and &coltype=N %then %do;
        /* if numeric match exactly */
        or ("&col"n = &numval)
      %end;
    %end;
      );
    %if &outobs>-1 %then %do;
      if _n_ > &outobs then stop;
    %end;
    run;
    %put Search query for &table took
      %sysevalf(%sysfunc(datetime())-&check_tm) seconds;
    %if &syscc ne 0 %then %do;
      %put %str(ERR)ROR: SYSCC=&syscc when processing &lib..&table;
      %return;
    %end;
    %if %mf_nobs(&outlib..&table)=0 %then %do;
      proc sql;
      drop table &outlib..&table;
    %end;
  %end;
%end;

%put process finished at %sysfunc(datetime(),datetime19.);

%mend mp_searchdata;
/**
  @file
  @brief Logs a key value pair a control dataset
  @details If the dataset does not exist, it is created.  Usage:

      %mp_setkeyvalue(someindex,22,type=N)
      %mp_setkeyvalue(somenewindex,somevalue)

  <h4> SAS Macros </h4>
  @li mf_existds.sas

  <h4> Related Macros </h4>
  @li mf_getvalue.sas

  @param [in] key Provide a key on which to perform the lookup
  @param [in] value Provide a value
  @param [in] type= either C or N will populate valc and valn respectively.
    C is default.
  @param [out] libds= define the target table to hold the parameters

  @version 9.2
  @author Allan Bowe
  @source https://github.com/sasjs/core

**/

%macro mp_setkeyvalue(key,value,type=C,libds=work.mp_setkeyvalue
)/*/STORE SOURCE*/;

  %if not (%mf_existds(&libds)) %then %do;
    data &libds (index=(key/unique));
      length key $64 valc $2048 valn 8 type $1;
      call missing(of _all_);
      stop;
    run;
  %end;

  proc sql;
    delete from &libds
      where key=symget('key');
    insert into &libds
      set key=symget('key')
  %if &type=C %then %do;
        ,valc=symget('value')
        ,type='C'
  %end;
  %else %do;
        ,valn=symgetn('value')
        ,type='N'
  %end;
  ;

  quit;

%mend mp_setkeyvalue;/**
  @file
  @brief Sorts a SAS dataset in place, preserving constraints
  @details Generally if a dataset contains indexes, then it is not necessary to
  sort it before performing operations such as merges / joins etc.
  That said, there are a few edge cases where it can be desirable:

    @li To allow adjacent records to be viewed directly in the dataset
    @li To apply compression, or to remove deleted records
    @li To improve performance for specific queries

  This macro will only work for BASE (V9) engine libraries.  It works by
  creating a copy of the dataset (without data, WITH constraints) in the same
  library, appending a sorted view into it, and finally - renaming it.

  Example usage:

      proc sql;
      create table work.example as
        select * from sashelp.class;
      alter table work.example
        add constraint pk primary key(name);
      %mp_sortinplace(work.example)

  @param [in] libds The libref.datasetname that needs to be sorted

  <h4> SAS Macros </h4>
  @li mf_existds.sas
  @li mf_getengine.sas
  @li mf_getquotedstr.sas
  @li mf_getuniquename.sas
  @li mf_getvarlist.sas
  @li mf_nobs.sas
  @li mp_abort.sas
  @li mp_getpk.sas

  <h4> Related Macros </h4>
  @li mp_sortinplace.test.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_sortinplace(libds
)/*/STORE SOURCE*/;

%local lib ds tempds1 tempds2 tempvw sortkey;

/* perform validations */
%mp_abort(iftrue=(%sysfunc(countc(&libds,.)) ne 1)
  ,mac=mp_sortinplace
  ,msg=%str(LIBDS (&libds) should have LIBREF.DATASET format)
)
%mp_abort(iftrue=(%mf_existds(&libds)=0)
  ,mac=mp_sortinplace
  ,msg=%str(&libds does not exist)
)

%let lib=%scan(&libds,1,.);
%let ds=%scan(&libds,2,.);
%mp_abort(iftrue=(%mf_getengine(&lib) ne V9)
  ,mac=mp_sortinplace
  ,msg=%str(&lib is not a BASE engine library)
)

/* grab a copy of the constraints so we know what to sort by */
%let tempds1=%mf_getuniquename(prefix=&sysmacroname);
%mp_getpk(lib=&lib,ds=&ds,outds=work.&tempds1)

%if %mf_nobs(work.&tempds1)=0 %then %do;
  %put &sysmacroname: No PK found in &lib..&ds;
  %put Sorting will not take place;
  %return;
%end;

/* fallback sortkey is all fields */
%let sortkey=%mf_getvarlist(&libds);

/* overlay actual sort key if it exists */
data _null_;
  set work.&tempds1;
  call symputx('sortkey',coalescec(pk_fields,symget('sortkey')));
run;


/* create empty copy, with ALL constraints, in the same library */
%let tempds2=%mf_getuniquename(prefix=&sysmacroname);
proc append base=&lib..&tempds2 data=&libds(obs=0);
run;

/* create sorted view */
%let tempvw=%mf_getuniquename(prefix=&sysmacroname);
proc sql;
create view work.&tempvw as select * from &lib..&ds
order by %mf_getquotedstr(&sortkey,quote=N);

/* append sorted data */
proc append base=&lib..&tempds2 data=work.&tempvw;
run;

/* do validations */
%mp_abort(iftrue=(&syscc ne 0)
  ,mac=mp_sortinplace
  ,msg=%str(syscc=&syscc prior to replace operation)
)
%mp_abort(iftrue=(%mf_nobs(&lib..&tempds2) ne %mf_nobs(&lib..&ds))
  ,mac=mp_sortinplace
  ,msg=%str(new dataset has a different number of logical obs to the old)
)

/* drop old dataset */
proc sql;
drop table &lib..&ds;

/* rename the new dataset */
proc datasets library=&lib;
  change &tempds2=&ds;
run;


%mend mp_sortinplace;/**
  @file
  @brief Converts deletes/changes/appends into a single audit table.
  @details When tracking changes to data over time, it can be helpful to have
    a single base table to track ALL modifications - enabling audit trail,
    data recovery, and change re-application.  This macro is one of many
    data management utilities used in [Data Controller for SAS](
    https:datacontroller.io) - a comprehensive data ingestion solution, which
    works on any SAS platform (Viya, SAS 9, Foundation) and is free for up to 5
    users.

    NOTE - this macro does not validate the inputs. It is assumed that the
    datasets containing the new / changed / deleted rows are CORRECT, contain
    no additional (or missing columns), and that the originals dataset contains
    all relevant base records (and no additionals).

    Usage:

        data work.orig work.deleted work.changed work.appended;
          set sashelp.class;
          if _n_=1 then do;
            output work.orig work.deleted;
          end;
          else if _n_=2 then do;
            output work.orig;
            age=99;
            output work.changed;
          end;
          else do;
            name='Newbie';
            output work.appended;
            stop;
          end;
        run;

        %mp_storediffs(sashelp.class,work.orig,NAME
          ,delds=work.deleted
          ,modds=work.changed
          ,appds=work.appended
          ,outds=work.final
          ,mdebug=1
        )

  @param [in] libds Target table against which the changes were applied
  @param [in] origds Dataset with original (unchanged) records.  Can be empty if
    only appending.
  @param [in] key Space seperated list of key variables
  @param [in] delds= (0) Dataset with deleted records
  @param [in] appds= (0) Dataset with appended records
  @param [in] modds= (0) Dataset with modified records
  @param [out] outds= (work.mp_storediffs) Output table containing stored data.
    Has the following format:

        proc sql;
        create table &outds(
          load_ref char(36) label='unique load reference',
          processed_dttm num format=E8601DT26.6 label='Processed at timestamp',
          libref char(8) label='Library Reference (8 chars)',
          dsn char(32) label='Dataset Name (32 chars)',
          key_hash char(32) label=
            'MD5 Hash of primary key values (pipe seperated)',
          move_type char(1) label='Either (A)ppended, (D)eleted or (M)odified',
          is_pk num label='Is Primary Key Field? (1/0)',
          is_diff num label=
            'Did value change? (1/0/-1).  Always -1 for appends and deletes.',
          tgtvar_type char(1) label='Either (C)haracter or (N)umeric',
          tgtvar_nm char(32) label='Target variable name (32 chars)',
          oldval_num num format=best32. label='Old (numeric) value',
          newval_num num format=best32. label='New (numeric) value',
          oldval_char char(32765) label='Old (character) value',
          newval_char char(32765) label='New (character) value',
          constraint pk_mpe_audit
            primary key(load_ref,libref,dsn,key_hash,tgtvar_nm)
        );

    @param [in] processed_dttm= (0) Provide a datetime constant in relation to
      the actual load time.  If not provided, current timestamp is used.
    @param [in] mdebug= set to 1 to enable DEBUG messages and preserve outputs
    @param [out] loadref= (0) Provide a unique key to reference the load,
      otherwise a UUID will be generated.

  <h4> SAS Macros </h4>
  @li mf_getquotedstr.sas
  @li mf_getuniquename.sas
  @li mf_getvarlist.sas

  @version 9.2
  @author Allan Bowe
**/
/** @cond */

%macro mp_storediffs(libds
  ,origds
  ,key
  ,delds=0
  ,appds=0
  ,modds=0
  ,outds=work.mp_storediffs
  ,loadref=0
  ,processed_dttm=0
  ,mdebug=0
)/*/STORE SOURCE*/;
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

/* set up unique and temporary vars */
%local ds1 ds2 ds3 ds4 hashkey inds_auto inds_keep dslist;
%let ds1=%upcase(work.%mf_getuniquename(prefix=mpsd_ds1));
%let ds2=%upcase(work.%mf_getuniquename(prefix=mpsd_ds2));
%let ds3=%upcase(work.%mf_getuniquename(prefix=mpsd_ds3));
%let ds4=%upcase(work.%mf_getuniquename(prefix=mpsd_ds4));
%let hashkey=%upcase(%mf_getuniquename(prefix=mpsd_hashkey));
%let inds_auto=%upcase(%mf_getuniquename(prefix=mpsd_inds_auto));
%let inds_keep=%upcase(%mf_getuniquename(prefix=mpsd_inds_keep));

%let dslist=&origds;
%if &delds ne 0 %then %do;
  %let delds=%upcase(&delds);
  %if %scan(&delds,-1,.)=&delds %then %let delds=WORK.&delds;
  %let dslist=&dslist &delds;
%end;
%if &appds ne 0 %then %do;
  %let appds=%upcase(&appds);
  %if %scan(&appds,-1,.)=&appds %then %let appds=WORK.&appds;
  %let dslist=&dslist &appds;
%end;
%if &modds ne 0 %then %do;
  %let modds=%upcase(&modds);
  %if %scan(&modds,-1,.)=&modds %then %let modds=WORK.&modds;
  %let dslist=&dslist &modds;
%end;

%let origds=%upcase(&origds);
%if %scan(&origds,-1,.)=&origds %then %let origds=WORK.&origds;

%let key=%upcase(&key);

/* hash the key and append all the tables (marking the source) */
data &ds1;
  set &dslist indsname=&inds_auto;
  &hashkey=put(md5(catx('|',%mf_getquotedstr(&key,quote=N))),$hex32.);
  &inds_keep=&inds_auto;
proc sort;
  by &inds_keep &hashkey;
run;

/* transpose numeric & char vars */
proc transpose data=&ds1
    out=&ds2(rename=(&hashkey=key_hash _name_=tgtvar_nm col1=newval_num));
  by &inds_keep &hashkey;
  var _numeric_;
run;
proc transpose data=&ds1
    out=&ds3(
      rename=(&hashkey=key_hash _name_=tgtvar_nm col1=newval_char)
      where=(tgtvar_nm not in ("&hashkey","&inds_keep"))
    );
  by &inds_keep &hashkey;
  var _character_;
run;
data &ds4;
  length &inds_keep $41 tgtvar_nm $32;
  set &ds2 &ds3 indsname=&inds_auto;

  tgtvar_nm=upcase(tgtvar_nm);
  if tgtvar_nm in (%upcase(%mf_getvarlist(&libds,dlm=%str(,),quote=DOUBLE)));

  if &inds_auto="&ds2" then tgtvar_type='N';
  else if &inds_auto="&ds3" then tgtvar_type='C';
  else do;
    putlog "%str(ERR)OR: unidentified vartype input!" &inds_auto;
    call symputx('syscc',98);
  end;

  if &inds_keep="&appds" then move_type='A';
  else if &inds_keep="&delds" then move_type='D';
  else if &inds_keep="&modds" then move_type='M';
  else if &inds_keep="&origds" then move_type='O';
  else do;
    putlog "%str(ERR)OR: unidentified movetype input!" &inds_keep;
    call symputx('syscc',99);
  end;
  tgtvar_nm=upcase(tgtvar_nm);
  if tgtvar_nm in (%mf_getquotedstr(&key)) then is_pk=1;
  else is_pk=0;
  drop &inds_keep;
run;

%if "&loadref"="0" %then %let loadref=%sysfunc(uuidgen());
%if &processed_dttm=0 %then %let processed_dttm=%sysfunc(datetime());
%let libds=%upcase(&libds);

/* join orig vals for modified & deleted */
proc sql;
create table &outds as
  select "&loadref" as load_ref length=36
    ,&processed_dttm as processed_dttm format=E8601DT26.6
    ,"%scan(&libds,1,.)" as libref length=8
    ,"%scan(&libds,2,.)" as dsn length=32
    ,b.key_hash length=32
    ,b.move_type length=1
    ,b.tgtvar_nm length=32
    ,b.is_pk
    ,case when b.move_type ne 'M' then -1
      when a.newval_num=b.newval_num and a.newval_char=b.newval_char then 0
      else 1
      end as is_diff
    ,b.tgtvar_type length=1
    ,case when b.move_type='D' then b.newval_num
      else a.newval_num
      end as oldval_num format=best32.
    ,case when b.move_type='D' then .
      else b.newval_num
      end as newval_num format=best32.
    ,case when b.move_type='D' then b.newval_char
      else a.newval_char
      end as oldval_char length=32765
    ,case when b.move_type='D' then ''
      else b.newval_char
      end as newval_char length=32765
  from &ds4(where=(move_type='O')) as a
  right join &ds4(where=(move_type ne 'O')) as b
  on a.tgtvar_nm=b.tgtvar_nm
  and a.key_hash=b.key_hash
  order by move_type, key_hash,is_pk desc, tgtvar_nm;

%if &mdebug=0 %then %do;
  proc sql;
  drop table &ds1, &ds2, &ds3, &ds4;
%end;

%mend mp_storediffs;
/** @endcond *//**
  @file
  @brief Capture session start / finish times and request details
  @details For details, see
  https://rawsas.com/event-logging-of-stored-process-server-sessions.
    Requires a base table in the following structure (name can be changed):

    proc sql;
    create table &libds(
      request_dttm num not null format=datetime.
      ,status_cd char(4) not null
      ,_metaperson varchar(100) not null
      ,_program varchar(500)
      ,sysuserid varchar(50)
      ,sysjobid varchar(12)
      ,_sessionid varchar(50)
    );

    Called via STP init / term events (configurable in SMC) as follows:

    %mp_stprequests(status_cd=INIT, libds=YOURLIB.DATASET )


  @param status_cd= Use INIT for INIT and TERM for TERM events
  @param libds= Location of base table (library.dataset).  To minimise risk
    of table locks, we HIGHLY recommend using a database (NOT a SAS dataset).
    THE LIBRARY SHOULD BE ASSIGNED ALREADY - eg in autoexec or earlier in the
    init program proper.

  @version 9.2
  @author Allan Bowe
  @source https://github.com/sasjs/core

**/

%macro mp_stprequests(status_cd= /* $4 eg INIT or TERM */
      ,libds=somelib.stp_requests /* base table location  */
)/*/STORE SOURCE*/;

  /* set nosyntaxcheck so the code runs regardless */
  %local etls_syntaxcheck;
  %let etls_syntaxcheck=%sysfunc(getoption(syntaxcheck));
  options nosyntaxcheck;

  data ;
    if 0 then set &libds;
    request_dttm=datetime();
    status_cd="&status_cd";
    _METAPERSON="&_metaperson";
    _PROGRAM="&_program";
    SYSUSERID="&sysuserid";
    SYSJOBID="&sysjobid";
  %if not %symexist(_SESSIONID) %then %do;
    /* session id is stored in the replay variable but needs to be extracted */
    _replay=symget('_replay');
    _replay=subpad(_replay,index(_replay,'_sessionid=')+11,length(_replay));
    index=index(_replay,'&')-1;
    if index=-1 then index=length(_replay);
    _replay=substr(_replay,1,index);
    _SESSIONID=_replay;
    drop _replay index;
  %end;
  %else %do;
    /* explicitly created sessions are automatically available */
    _SESSIONID=symget('_SESSIONID');
  %end;
    output;
    stop;
  run;

  proc append base=&libds data=&syslast nowarn;run;

  options &etls_syntaxcheck;
%mend mp_stprequests;/**
  @file
  @brief Streams a file to _webout according to content type
  @details Will set headers using appropriate functions (SAS 9 vs Viya) and send
  content as a binary stream.

  Usage:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %mp_streamfile(contenttype=csv,inloc=/some/where.txt,outname=myfile.txt)

  <h4> SAS Macros </h4>
  @li mf_getplatform.sas
  @li mp_binarycopy.sas

  @param contenttype= Either TEXT, ZIP, CSV, EXCEL (default TEXT)
  @param inloc= /path/to/file.ext to be sent
  @param inref= fileref of file to be sent (if provided, overrides `inloc`)
  @param outname= the name of the file, as downloaded by the browser

  @author Allan Bowe
  @source https://github.com/sasjs/core

**/

%macro mp_streamfile(
  contenttype=TEXT
  ,inloc=
  ,inref=0
  ,outname=
)/*/STORE SOURCE*/;

%let contentype=%upcase(&contenttype);
%local platform; %let platform=%mf_getplatform();


/**
  * check engine type to avoid the below err message:
  * > Function is only valid for filerefs using the CACHE access method.
  */
%local streamweb;
%let streamweb=0;
data _null_;
  set sashelp.vextfl(where=(upcase(fileref)="_WEBOUT"));
  if xengine='STREAM' then call symputx('streamweb',1,'l');
run;

%if &contentype=ZIP %then %do;
  %if &platform=SASMETA and &streamweb=1 %then %do;
    data _null_;
      rc=stpsrv_header('Content-type','application/zip');
      rc=stpsrv_header('Content-disposition',"attachment; filename=&outname");
    run;
  %end;
  %else %if &platform=SASVIYA %then %do;
    filename _webout filesrvc parenturi="&SYS_JES_JOB_URI" name='_webout.zip'
      contenttype='application/zip'
      contentdisp="attachment; filename=&outname";
  %end;
%end;
%else %if &contentype=EXCEL %then %do;
  /* suitable for XLS format */
  %if &platform=SASMETA and &streamweb=1 %then %do;
    data _null_;
      rc=stpsrv_header('Content-type','application/vnd.ms-excel');
      rc=stpsrv_header('Content-disposition',"attachment; filename=&outname");
    run;
  %end;
  %else %if &platform=SASVIYA %then %do;
    filename _webout filesrvc parenturi="&SYS_JES_JOB_URI" name='_webout.xls'
      contenttype='application/vnd.ms-excel'
      contentdisp="attachment; filename=&outname";
  %end;
%end;
%else %if &contentype=XLSX %then %do;
  %if &platform=SASMETA and &streamweb=1 %then %do;
    data _null_;
      rc=stpsrv_header('Content-type',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      rc=stpsrv_header('Content-disposition',"attachment; filename=&outname");
    run;
  %end;
  %else %if &platform=SASVIYA %then %do;
    filename _webout filesrvc parenturi="&SYS_JES_JOB_URI" name='_webout.xls'
      contenttype=
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      contentdisp="attachment; filename=&outname";
  %end;
%end;
%else %if &contentype=TEXT %then %do;
  %if &platform=SASMETA and &streamweb=1 %then %do;
    data _null_;
      rc=stpsrv_header('Content-type','application/text');
      rc=stpsrv_header('Content-disposition',"attachment; filename=&outname");
    run;
  %end;
  %else %if &platform=SASVIYA %then %do;
    filename _webout filesrvc parenturi="&SYS_JES_JOB_URI" name='_webout.txt'
      contenttype='application/text'
      contentdisp="attachment; filename=&outname";
  %end;
%end;
%else %if &contentype=CSV %then %do;
  %if &platform=SASMETA and &streamweb=1 %then %do;
    data _null_;
      rc=stpsrv_header('Content-type','application/csv');
      rc=stpsrv_header('Content-disposition',"attachment; filename=&outname");
    run;
  %end;
  %else %if &platform=SASVIYA %then %do;
    filename _webout filesrvc parenturi="&SYS_JES_JOB_URI" name='_webout.txt'
      contenttype='application/csv'
      contentdisp="attachment; filename=&outname";
  %end;
%end;
%else %if &contentype=HTML %then %do;
  %if &platform=SASVIYA %then %do;
    filename _webout filesrvc parenturi="&SYS_JES_JOB_URI" name="_webout.json"
      contenttype="text/html";
  %end;
%end;
%else %do;
  %put %str(ERR)OR: Content Type &contenttype NOT SUPPORTED by &sysmacroname!;
  %return;
%end;

%if &inref ne 0 %then %do;
  %mp_binarycopy(inref=&inref,outref=_webout)
%end;
%else %do;
  %mp_binarycopy(inloc="&inloc",outref=_webout)
%end;

%mend mp_streamfile;
/**
  @file
  @brief Runs arbitrary code for a specified amount of time
  @details Executes a series of procs and data steps to enable performance
  testing of arbitrary jobs.

      %mp_testjob(
        duration=60*5
      )

  @param [in] duration= the time in seconds which the job should run for. Actual
  time may vary, as the check is done in between steps.  Default = 30 (seconds).

  <h4> SAS Macros </h4>
  @li mf_getuniquelibref.sas
  @li mf_getuniquename.sas
  @li mf_mkdir.sas

  @version 9.4
  @author Allan Bowe

**/

%macro mp_testjob(duration=30
)/*/STORE SOURCE*/;
%local lib dir ds1 ds2 ds3 start_tm i;

%let start_tm=%sysfunc(datetime());
%let duration=%sysevalf(&duration);

/* create a temporary library in WORK */
%let lib=%mf_getuniquelibref();
%let dir=%mf_getuniquename();
%mf_mkdir(%sysfunc(pathname(work))/&dir)
libname &lib "%sysfunc(pathname(work))/&dir";

/* loop through until time expires */
%let ds1=%mf_getuniquename();
%let ds2=%mf_getuniquename();
%let ds3=%mf_getuniquename();
%do i=0 %to 1;

  /* create big dataset */
  data &lib..&ds1(compress=no );
    do x=1 to 1000000;
      randnum0=ranuni(0)*3;
      randnum1=ranuni(0)*2;
      bigchar=repeat('A',300);
      output;
    end;
  run;
  %if %sysevalf( (%sysfunc(datetime())-&start_tm)>&duration ) %then %goto gate;

  proc summary ;
    class randnum0 randnum1;
    output out=&lib..&ds2;
  run;quit;
  %if %sysevalf( (%sysfunc(datetime())-&start_tm)>&duration ) %then %goto gate;

  /* add more data */
  proc sql;
  create table &lib..&ds3 as
    select *, ranuni(0)*10 as randnum2
  from &lib..&ds1
  order by randnum1;
  quit;
  %if %sysevalf( (%sysfunc(datetime())-&start_tm)>&duration ) %then %goto gate;

  proc sort data=&lib..&ds3;
    by descending x;
  run;
  %if %sysevalf( (%sysfunc(datetime())-&start_tm)>&duration ) %then %goto gate;

  /* wait 5 seconds */
  data _null_;
    call sleep(5,1);
  run;
  %if %sysevalf( (%sysfunc(datetime())-&start_tm)>&duration ) %then %goto gate;

  %let i=0;

%end;

%gate:
%put time is up!;
proc datasets lib=&lib kill;
run;
quit;
libname &lib clear;


%mend mp_testjob;/**
  @file mp_testservice.sas
  @brief Will execute a test against a SASjs web service on SAS 9 or Viya
  @details Prepares the input files and retrieves the resulting datasets from
  the response JSON.

      %mp_testjob(
        duration=60*5
      )

  Note - the _webout fileref should NOT be assigned prior to running this macro.

  @param [in] program The _PROGRAM endpoint to test
  @param [in] inputfiles=(0) A list of space seperated fileref:filename pairs as
    follows:
        inputfiles=inref:filename inref2:filename2
  @param [in] inputparams=(0) A dataset containing name/value pairs in the
    following format:
    |name:$32|value:$1000|
    |---|---|
    |stpmacname|some value|
    |mustbevalidname|can be anything, oops, %abort!!|

  @param [in] debug= (log) Provide the _debug value
  @param [in] mdebug= (0) Set to 1 to provide macro debugging
  @param [in] viyaresult= (WEBOUT_JSON) The Viya result type to return.  For
    more info, see mv_getjobresult.sas
  @param [in] viyacontext= (SAS Job Execution compute context) The Viya compute
    context on which to run the service
  @param [out] outlib= (0) Output libref to contain the final tables.  Set to
    0 if the service output is not in JSON format.
  @param [out] outref= (0) Output fileref to create, to contain the full _webout
    response.

  <h4> SAS Macros </h4>
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquename.sas
  @li mp_abort.sas
  @li mp_binarycopy.sas
  @li mv_getjobresult.sas
  @li mv_jobflow.sas

  @version 9.4
  @author Allan Bowe

**/

%macro mp_testservice(program,
  inputfiles=0,
  inputparams=0,
  debug=log,
  mdebug=0,
  outlib=0,
  outref=0,
  viyaresult=WEBOUT_JSON,
  viyacontext=SAS Job Execution compute context
)/*/STORE SOURCE*/;
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

/* sanitise inputparams */
%local pcnt;
%let pcnt=0;
%if &inputparams ne 0 %then %do;
  data _null_;
    set &inputparams;
    if not nvalid(name,'v7') then putlog (_all_)(=);
    else if name in (
      'program','inputfiles','inputparams','debug','outlib','outref'
    ) then putlog (_all_)(=);
    else do;
      x+1;
      call symputx(name,quote(cats(value)),'l');
      call symputx('pval'!!left(x),name,'l');
      call symputx('pcnt',x,'l');
    end;
  run;
  %mp_abort(iftrue= (%mf_nobs(&inputparams) ne &pcnt)
    ,mac=&sysmacroname
    ,msg=%str(Invalid values in &inputparams)
  )
%end;


%local fref1 webref;
%let fref1=%mf_getuniquefileref();
%let webref=%mf_getuniquefileref();

%local platform;
%let platform=%mf_getplatform();
%if &platform=SASMETA %then %do;

  /* parse the input files */
  %local webcount i var;
  %if %quote(&inputfiles) ne 0 %then %do;
    %let webcount=%sysfunc(countw(&inputfiles));
    %put &=webcount;
    %do i=1 %to &webcount;
      %let var=%scan(&inputfiles,&i,%str( ));
      %local webfref&i webname&i;
      %let webref&i=%scan(&var,1,%str(:));
      %let webname&i=%scan(&var,2,%str(:));
      %put webref&i=&&webref&i;
      %put webname&i=&&webname&i;
    %end;
  %end;
  %else %let webcount=0;

  proc stp program="&program";
    inputparam _program="&program"
  %do i=1 %to &webcount;
    %if &webcount=1 %then %do;
      _webin_fileref="&&webref&i"
      _webin_name="&&webname&i"
    %end;
    %else %do;
      _webin_fileref&i="&&webref&i"
      _webin_name&i="&&webname&i"
    %end;
  %end;
    _webin_file_count="&webcount"
    _debug="&debug"
  %do i=1 %to &pcnt;
    /* resolve name only, proc stp fetches value */
    &&pval&i=&&&&&&pval&i
  %end;
    ;
  %do i=1 %to &webcount;
    inputfile &&webref&i;
  %end;
    outputfile _webout=&webref;
  run;

  data _null_;
    infile &webref;
    file &fref1;
    input;
    length line $10000;
    if index(_infile_,'>>weboutBEGIN<<') then do;
        line=tranwrd(_infile_,'>>weboutBEGIN<<','');
        put line;
    end;
    else if index(_infile_,'>>weboutEND<<') then do;
        line=tranwrd(_infile_,'>>weboutEND<<','');
        put line;
        stop;
    end;
    else put _infile_;
  run;
  data _null_;
    infile &fref1;
    input;
    put _infile_;
  run;
  %if &outlib ne 0 %then %do;
    libname &outlib json (&fref1);
  %end;
  %if &outref ne 0 %then %do;
    filename &outref temp;
    %mp_binarycopy(inref=&webref,outref=&outref)
  %end;

%end;
%else %if &platform=SASVIYA %then %do;

  /* prepare inputparams */
  %local ds1;
  %let ds1=%mf_getuniquename();
  %if "&inputparams" ne "0" %then %do;
    proc transpose data=&inputparams out=&ds1;
      id name;
      var value;
    run;
  %end;
  %else %do;
    data &ds1;run;
  %end;

  /* parse the input files - convert to sasjs params */
  %local webcount i var sasjs_tables;
  %if %quote(&inputfiles) ne 0 %then %do;
    %let webcount=%sysfunc(countw(&inputfiles));
    %put &=webcount;
    %do i=1 %to &webcount;
      %let var=%scan(&inputfiles,&i,%str( ));
      %local webfref&i webname&i sasjs&i.data;
      %let webref&i=%scan(&var,1,%str(:));
      %let webname&i=%scan(&var,2,%str(:));
      %put webref&i=&&webref&i;
      %put webname&i=&&webname&i;

      %let sasjs_tables=&sasjs_tables &&webname&i;
      data _null_;
        infile &&webref&i lrecl=32767;
        input;
        if _n_=1 then call symputx("sasjs&i.data",_infile_);
        else call symputx(
          "sasjs&i.data",cats(symget("sasjs&i.data"),'0D0A'x,_infile_)
        );
        putlog "&sysmacroname infile: " _infile_;
      run;
      data &ds1;
        set &ds1;
        length sasjs&i.data $32767 sasjs_tables $1000;
        sasjs&i.data=symget("sasjs&i.data");
        sasjs_tables=symget("sasjs_tables");
      run;
    %end;
  %end;
  %else %let webcount=0;

  data &ds1;
    retain _program "&program";
    retain _contextname "&viyacontext";
    set &ds1;
    putlog "&sysmacroname inputparams:";
    putlog (_all_)(=);
  run;

  %mv_jobflow(inds=&ds1
    ,maxconcurrency=1
    ,outds=work.results
    ,outref=&fref1
    ,mdebug=&mdebug
  )
  /* show the log */
  data _null_;
    infile &fref1;
    input;
    putlog _infile_;
  run;
  /* get the uri to fetch results */
  data _null_;
    set work.results;
    call symputx('uri',uri);
    putlog "&sysmacroname: fetching results for " uri;
  run;
  /* fetch results from webout.json */
  %mv_getjobresult(uri=&uri,
    result=&viyaresult,
    outref=&outref,
    outlib=&outlib,
    mdebug=&mdebug
  )

%end;
%else %do;
  %put %str(ERR)OR: Unrecognised platform:  &platform;
%end;

%if &mdebug=0 %then %do;
  filename &webref clear;
%end;
%else %do;
  %put &sysmacroname exit vars:;
  %put _local_;
%end;

%mend mp_testservice;/**
  @file mp_testwritespeedlibrary.sas
  @brief Tests the write speed of a new table in a SAS library
  @details Will create a new table of a certain size in an
  existing SAS library.  The table will have one column,
  and will be subsequently deleted.

      %mp_testwritespeedlibrary(
        lib=work
        ,size=0.5
        ,outds=work.results
      )

  @param lib= (WORK) The library in which to create the table
  @param size= (0.1) The size in GB of the table to create
  @param outds= (WORK.RESULTS) The output dataset to be created.

  <h4> SAS Macros </h4>
  @li mf_getuniquename.sas
  @li mf_existds.sas

  @version 9.4
  @author Allan Bowe

**/

%macro mp_testwritespeedlibrary(lib=WORK
  ,outds=work.results
  ,size=0.1
)/*/STORE SOURCE*/;
%local ds start;

/* find an unused, unique name for the new table */
%let ds=%mf_getuniquename();
%do %until(%mf_existds(&lib..&ds)=0);
  %let ds=%mf_getuniquename();
%end;

%let start=%sysfunc(datetime());

data &lib..&ds(compress=no keep=x);
  header=128*1024;
  size=(1073741824/8 * &size) - header;
  do x=1 to size;
    output;
  end;
run;

proc sql;
drop table &lib..&ds;

data &outds;
  lib="&lib";
  start_dttm=put(&start,datetime19.);
  end_dttm=put(datetime(),datetime19.);
  duration_seconds=end_dttm-start_dttm;
run;

%mend mp_testwritespeedlibrary;/**
  @file
  @brief Recursively scans a directory tree to get all subfolders and content
  @details
  Usage:

      %mp_tree(dir=/tmp, outds=work.tree)

  Credits:

  Roger Deangelis:
https://communities.sas.com/t5/SAS-Programming/listing-all-files-within-a-directory-and-subdirectories/m-p/332616/highlight/true#M74887

  Tom:
https://communities.sas.com/t5/SAS-Programming/listing-all-files-of-all-types-from-all-subdirectories/m-p/334113/highlight/true#M75419


  @param dir= Directory to be scanned (default=/tmp)
  @param outds= Dataset to create (default=work.mp_tree)

  @returns outds contains the following variables:

    - `dir`: a flag (1/0) to say whether it is a directory or not.  This is not
      reliable - folders that you do not have permission to open will be flagged
      as directories.
    - `ext`: file extension
    - `filename`: file name
    - `dirname`: directory name
    - `fullpath`: directory + file name

  @version 9.2
**/

%macro mp_tree(dir=/tmp
  ,outds=work.mp_tree
)/*/STORE SOURCE*/;

data &outds ;
  length dir 8 ext filename dirname $256 fullpath $512 ;
  call missing(of _all_);
  fullpath = "&dir";
run;

%local sep;
%if &sysscp=WIN or &SYSSCP eq DNTHOST %then %let sep=\;
%else %let sep=/;

data &outds ;
  modify &outds ;
  retain sep "&sep";
  rc=filename('tmp',fullpath);
  dir_id=dopen('tmp');
  dir = (dir_id ne 0) ;
  if dir then dirname=fullpath;
  else do;
    filename=scan(fullpath,-1,sep) ;
    dirname =substrn(fullpath,1,length(fullpath)-length(filename));
    if index(filename,'.')>1 then ext=scan(filename,-1,'.');
  end;
  replace;
  if dir then do;
    do i=1 to dnum(dir_id);
      fullpath=cats(dirname,sep,dread(dir_id,i));
      output;
    end;
    rc=dclose(dir_id);
  end;
  rc=filename('tmp');
run;

%mend mp_tree;/**
  @file mp_unzip.sas
  @brief Unzips a zip file
  @details Opens the zip file and copies all the contents to another directory.
  It is not possible to retain permissions / timestamps, also the BOF marker
  is lost so it cannot extract binary files.

  Usage:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %mp_unzip(ziploc="/some/file.zip",outdir=/some/folder)

  More info:  https://blogs.sas.com/content/sasdummy/2015/05/11/using-filename-zip-to-unzip-and-read-data-files-in-sas/

  @param ziploc= Fileref or quoted full path to zip file ("/path/to/file.zip")
  @param outdir= (%sysfunc(pathname(work))) Directory in which to write the
    outputs (created if non existant)

  <h4> SAS Macros </h4>
  @li mf_mkdir.sas
  @li mf_getuniquefileref.sas
  @li mp_binarycopy.sas

  @version 9.4
  @author Allan Bowe
  @source https://github.com/sasjs/core

**/

%macro mp_unzip(
  ziploc=
  ,outdir=%sysfunc(pathname(work))
)/*/STORE SOURCE*/;

%local f1 f2 ;
%let f1=%mf_getuniquefileref();
%let f2=%mf_getuniquefileref();

/* Macro variable &datazip would be read from the file */
filename &f1 ZIP &ziploc;

/* create target folder */
%mf_mkdir(&outdir)

/* Read the "members" (files) from the ZIP file */
data _data_(keep=memname isFolder);
  length memname $200 isFolder 8;
  fid=dopen("&f1");
  if fid=0 then stop;
  memcount=dnum(fid);
  do i=1 to memcount;
    memname=dread(fid,i);
    /* check for trailing / in folder name */
    isFolder = (first(reverse(trim(memname)))='/');
    output;
  end;
  rc=dclose(fid);
run;

filename &f2 temp;

/* loop through each entry and either create the subfolder or extract member */
data _null_;
  set &syslast;
  file &f2;
  if isFolder then call execute('%mf_mkdir(&outdir/'!!memname!!')');
  else do;
    qname=quote(cats("&outdir/",memname));
    bname=cats('(',memname,')');
    put '/* hat tip: "data _null_" on SAS-L */';
    put 'data _null_;';
    put '  infile &f1 ' bname ' lrecl=256 recfm=F length=length eof=eof unbuf;';
    put '  file ' qname ' lrecl=256 recfm=N;';
    put '  input;';
    put '  put _infile_ $varying256. length;';
    put '  return;';
    put 'eof:';
    put '  stop;';
    put 'run;';
  end;
run;

%inc &f2/source2;

filename &f2 clear;

%mend mp_unzip;
/**
  @file mp_updatevarlength.sas
  @brief Change the length of a variable
  @details The library is assumed to be assigned.  Simple character updates
  currently supported, numerics are more complicated and will follow.

        data example;
          a='1';
          b='12';
          c='123';
        run;
        %mp_updatevarlength(example,a,3)
        %mp_updatevarlength(example,c,1)
        proc sql;
        describe table example;

  @param libds the library.dataset to be modified
  @param var The variable to modify
  @param len The new length to apply

  <h4> SAS Macros </h4>
  @li mf_existds.sas
  @li mp_abort.sas
  @li mf_existvar.sas
  @li mf_getvarlen.sas
  @li mf_getvartype.sas
  @li mf_getnobs.sas
  @li mp_createconstraints.sas
  @li mp_getconstraints.sas
  @li mp_deleteconstraints.sas

  @version 9.2
  @author Allan Bowe

**/

%macro mp_updatevarlength(libds,var,len
)/*/STORE SOURCE*/;

%if %index(&libds,.)=0 %then %let libds=WORK.&libds;

%mp_abort(iftrue=(%mf_existds(&libds)=0)
  ,mac=&sysmacroname
  ,msg=%str(Table &libds not found!)
)

%mp_abort(iftrue=(%mf_existvar(&libds,&var)=0)
  ,mac=&sysmacroname
  ,msg=%str(Variable &var not found on &libds!)
)

/* not possible to in-place modify a numeric length, to add later */
%mp_abort(iftrue=(%mf_getvartype(&libds,&var)=0)
  ,mac=&sysmacroname
  ,msg=%str(Only character resizings are currently supported)
)

%local oldlen;
%let oldlen=%mf_getvarlen(&libds,&var);
%if  &oldlen=&len %then %do;
  %put &sysmacroname: Old and new lengths (&len) match!;
  %return;
%end;

%let libds=%upcase(&libds);


data;run;
%local dsconst; %let dsconst=&syslast;
%mp_getconstraints(lib=%scan(&libds,1,.),ds=%scan(&libds,2,.),outds=&dsconst)

%mp_abort(iftrue=(&syscc ne 0)
  ,mac=&sysmacroname
  ,msg=%str(syscc=&syscc)
)

%if %mf_getnobs(&dscont)=0 %then %do;
  /* must use SQL as proc datasets does not support length changes */
  proc sql;
  alter table &libds modify &var char(&len);
  %return;
%end;

/* we have constraints! */

%mp_deleteconstraints(inds=&dsconst,outds=&dsconst._dropd,execute=YES)

proc sql;
alter table &libds modify &var char(&len);

%mp_createconstraints(inds=&dsconst,outds=&dsconst._addd,execute=YES)

%mend mp_updatevarlength;
/**
  @file
  @brief Used to validate variables in a dataset
  @details Useful when sanitising inputs, to ensure that they arrive with a
  certain pattern.
  Usage:

      data test;
        infile datalines4 dsd;
        input;
        libds=_infile_;
        %mp_validatecol(libds,LIBDS,is_libds)
      datalines4;
      some.libname
      !lib.blah
      %abort
      definite.ok
      not.ok!
      nineletrs._
      ;;;;
      run;

  For more examples, see mp_validatecol.test.sas

  Tip - when contributing, use https://regex101.com to test the regex validity!

  @param [in] incol The column to be validated
  @param [in] rule The rule to apply.  Current rules:
    @li ISINT - checks if the variable is an integer
    @li ISNUM - checks if the variable is numeric
    @li LIBDS - matches LIBREF.DATASET format
    @li FORMAT - checks if the provided format is syntactically valid
  @param [out] outcol The variable to create, with the results of the match

  <h4> SAS Macros </h4>
  @li mf_getuniquename.sas

  <h4> Related Macros </h4>
  @li mp_validatecol.test.sas

  @version 9.3
**/

%macro mp_validatecol(incol,rule,outcol);

/* tempcol is given a unique name with every invocation */
%local tempcol;
%let tempcol=%mf_getuniquename();

%if &rule=ISINT %then %do;
  &tempcol=input(&incol,?? best32.);
  &outcol=0;
  if not missing(&tempcol) then if mod(&incol,1)=0 then &outcol=1;
  drop &tempcol;
%end;
%else %if &rule=ISNUM %then %do;
  /*
    credit SØREN LASSEN
    https://sasmacro.blogspot.com/2009/06/welcome-isnum-macro.html
  */
  &tempcol=input(&incol,?? best32.);
  if missing(&tempcol) then &outcol=0;
  else &outcol=1;
  drop &tempcol;
%end;
%else %if &rule=LIBDS %then %do;
  /* match libref.dataset */
  if _n_=1 then do;
    retain &tempcol;
    &tempcol=prxparse('/^[_a-z]\w{0,7}\.[_a-z]\w{0,31}$/i');
    if missing(&tempcol) then do;
      putlog "%str(ERR)OR: Invalid expression for LIBDS";
      stop;
    end;
    drop &tempcol;
  end;
  if prxmatch(&tempcol, trim(&incol)) then &outcol=1;
  else &outcol=0;
%end;
%else %if &rule=FORMAT %then %do;
  /* match valid format - regex could probably be improved */
  if _n_=1 then do;
    retain &tempcol;
    &tempcol=prxparse('/^[_a-z\$]\w{0,31}\.[0-9]*$/i');
    if missing(&tempcol) then do;
      putlog "%str(ERR)OR: Invalid expression for FORMAT";
      stop;
    end;
    drop &tempcol;
  end;
  if prxmatch(&tempcol, trim(&incol)) then &outcol=1;
  else &outcol=0;
%end;

%mend mp_validatecol;
/**
  @file
  @brief Wait until a file arrives before continuing execution
  @details Loops with a `sleep()` command until a file arrives or the max wait
  period expires.

  @example

  Wait 3 minutes OR for /tmp/flag.txt to appear

    %mp_wait4file(/tmp/flag.txt , maxwait=60*3)

  @param [in] file The file to wait for.  Must be provided.
  @param [in] maxwait= (0) Number of seconds to wait.  If set to zero, will
    loop indefinitely (to a maximum of 46 days, per SAS [documentation](
      https://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a001418809.htm
    )).  Otherwise, execution will proceed upon sleep expiry.
  @param [in] interval= (1) The wait period between sleeps, in seconds


**/

%macro mp_wait4file(file, maxwait=0, interval=1);

%if %str(&file)=%str() %then %do;
  %put %str(ERR)OR: file not provided;
%end;

data _null_;
  maxwait=&maxwait;
  if maxwait=0 then maxwait=60*60*24*46;
  do until (fileexist("&file") or slept>maxwait );
    slept=sum(slept,sleep(&interval,1));
  end;
run;

%mend mp_wait4file;/**
  @file
  @brief Fix the `_WEBIN` variables provided to SAS web services
  @details When uploading files to SAS Stored Processes or Viya Jobs a number
  of global macro variables are automatically created - however there are some
  differences in behaviour both between SAS 9 and Viya, and also between a
  single file upload and a multi-file upload.

  This macro "straightens" up the global macro variables to make it easier /
  simpler to write code that works in both environments and with a variable
  number of file inputs.

  After running this macro, the following global variables will *always* exist:
  @li `_WEBIN_FILE_COUNT`
  @li `_WEBIN_FILENAME1`
  @li `_WEBIN_FILEREF1`
  @li `_WEBIN_NAME1`

  Usage:

    %mp_webin()

  This was created as a macro procedure (over a macro function) as it will also
  use the filename statement in Viya environments (where `_webin_fileuri` is
  provided).

  <h4> SAS Macros </h4>
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas

**/

%macro mp_webin();

/* prepare global variables */
%global _webin_file_count
  _webin_filename _webin_filename1
  _webin_fileref _webin_fileref1
  _webin_fileuri _webin_fileuri1
  _webin_name _webin_name1
  ;

/* create initial versions */
%let _webin_file_count=%eval(&_webin_file_count+0);
%let _webin_filename1=%sysfunc(coalescec(&_webin_filename1,&_webin_filename));
%let _webin_fileref1=%sysfunc(coalescec(&_webin_fileref1,&_webin_fileref));
%let _webin_fileuri1=%sysfunc(coalescec(&_webin_fileuri1,&_webin_fileuri));
%let _webin_name1=%sysfunc(coalescec(&_webin_name1,&_webin_name));


/* If Viya, create temporary fileref(s) */
%local i;
%if %mf_getplatform()=SASVIYA %then %do i=1 %to &_webin_file_count;
  %let _webin_fileref&i=%mf_getuniquefileref();
  filename &&_webin_fileref&i filesrvc "&&_webin_fileuri&i";
%end;


%mend mp_webin;/**
  @file
  @brief Creates a zip file
  @details For DIRECTORY usage, will ignore subfolders. For DATASET usage,
  provide a column that contains the full file path to each file to be zipped.

      %mp_zip(in=myzips,type=directory,outname=myDir)
      %mp_zip(in=/my/file/path.txt,type=FILE,outname=myFile)
      %mp_zip(in=SOMEDS,incol=FPATH,type=DATASET,outname=myFile)

  If you are sending zipped output to the _webout destination as part of an STP
  be sure that _debug is not set (else the SPWA will send non zipped content
  as well).

  <h4> SAS Macros </h4>
  @li mp_dirlist.sas

  @param in= unquoted filepath, dataset of files or directory to zip
  @param type= (FILE) Valid values:
    @li FILE - /full/path/and/filename.extension to a particular file
    @li DATASET - a dataset containing a list of files to zip (see `incol`)
    @li DIRECTORY - a directory to zip
  @param outname= (FILE) Output file to create, _without_ .zip extension
  @param outpath= (%sysfunc(pathname(WORK))) Parent folder for output zip file
  @param incol= if DATASET input, say which column contains the filepath

  <h4> Related Macros </h4>
  @li mp_unzip.sas
  @li mp_zip.test.sas

  @version 9.2
  @author Allan Bowe
  @source https://github.com/sasjs/core

**/

%macro mp_zip(
  in=
  ,type=FILE
  ,outname=FILE
  ,outpath=%sysfunc(pathname(WORK))
  ,incol=
  ,debug=NO
)/*/STORE SOURCE*/;

%let type=%upcase(&type);
%local ds;

ods package open nopf;

%if &type=FILE %then %do;
  ods package add file="&in" mimetype="application/x-compress";
%end;
%else %if &type=DIRECTORY %then %do;
  %mp_dirlist(path=&in,outds=_data_)
  %let ds=&syslast;
  data _null_;
    set &ds;
    length __command $4000;
    if file_or_folder='file';
    __command=cats('ods package add file="',filepath
      ,'" mimetype="application/x-compress";');
    call execute(__command);
  run;
  /* tidy up */
  %if &debug=NO %then %do;
    proc sql; drop table &ds;quit;
  %end;
%end;
%else %if &type=DATASET %then %do;
  data _null_;
    set &in;
    length __command $4000;
    __command=cats('ods package add file="',&incol
      ,'" mimetype="application/x-compress";');
    call execute(__command);
  run;
%end;


ods package publish archive properties
  (archive_name="&outname..zip" archive_path="&outpath");
ods package close;

%mend mp_zip;/**
  @file mm_adduser2group.sas
  @brief Adds a user to a group
  @details Adds a user to a metadata group.  The macro first checks whether the
    user is in that group, and if not, the user is added.

  Usage:

      %mm_adduser2group(user=sasdemo
        ,group=someGroup)


  @param user= the user name (not displayname)
  @param group= the group to which to add the user
  @param mdebug= set to 1 to show debug info in log

  @warning the macro does not check inherited group memberships - it looks at
    direct members only

  @version 9.3
  @author Allan Bowe

**/

%macro mm_adduser2group(user=
  ,group=
  ,mdebug=0
);
/* first, check if user is in group already exists */
%local check uuri guri;
%let check=ok;

data _null_;
  length uri type msg $256;
  call missing(of _all_);
  rc=metadata_getnobj("omsobj:Person?@Name='&user'",1,uri);
  if rc<=0 then do;
    msg="%str(WARN)ING: rc="!!cats(rc)!!" &user not found "!!
        ", or there was an err reading the repository.";
    call symputx('check',msg);
    putlog msg;
    stop;
  end;
  call symputx('uuri',scan(uri,2,'\'));

  rc=metadata_getnobj("omsobj:IdentityGroup?@Name='&group'",1,uri);
  if rc<=0 then do;
    msg="%str(WARN)ING: rc="!!cats(rc)!!" &group not found "!!
        ", or there was an err reading the repository.";
    call symputx('check',msg);
    putlog msg;
    stop;
  end;
  call symputx('guri',scan(uri,2,'\'));

  rc=metadata_getnobj("omsobj:Person?Person[@Name='&user'][IdentityGroups/*[@Name='&group']]",1,uri);
  if rc=0 then do;
    msg="%str(WARN)ING: rc="!!cats(rc)!!" &user already in &group";
    call symputx('check',msg);
    stop;
  end;

  if &mdebug ne 0 then put (_all_)(=);
run;

/* stop if issues */
%if %quote(&check) ne %quote(ok) %then %do;
  %put &check;
  %return;
%end;

%if &syscc ge 4 %then %do;
  %put %str(WARN)ING:  SYSCC=&syscc, exiting &sysmacroname;
  %return;
%end;


filename __us2grp temp;

proc metadata in= "<UpdateMetadata><Reposid>$METAREPOSITORY</Reposid><Metadata>
    <Person Id='&uuri'><IdentityGroups><IdentityGroup ObjRef='&guri' />
    </IdentityGroups></Person></Metadata>
    <NS>SAS</NS><Flags>268435456</Flags></UpdateMetadata>"
  out=__us2grp verbose;
run;

%if &mdebug ne 0 %then %do;
  /* write the response to the log for debugging */
  data _null_;
    infile __us2grp lrecl=32767;
    input;
    put _infile_;
  run;
%end;

filename __us2grp clear;

%mend mm_adduser2group;/**
  @file
  @brief Assigns library directly using details from metadata
  @details Queries metadata to get the libname definition then allocates the
    library directly (ie, not using the META engine).
  usage:

      %mm_assignDirectLib(MyLib);
      data x; set mylib.sometable; run;

      %mm_assignDirectLib(MyDB,open_passthrough=MyAlias);
      create table MyTable as
        select * from connection to MyAlias( select * from DBTable);
      disconnect from MyAlias;
      quit;

  <h4> SAS Macros </h4>
  @li mf_getengine.sas
  @li mp_abort.sas

  @param libref the libref (not name) of the metadata library
  @param open_passthrough= provide an alias to produce the CONNECT TO statement
    for the relevant external database
  @param sql_options= an override default output fileref to avoid naming clash
  @param mDebug= set to 1 to show debug messages in the log
  @param mAbort= set to 1 to call %mp_abort().

  @returns libname statement

  @version 9.2
  @author Allan Bowe

**/

%macro mm_assigndirectlib(
    libref /* libref to assign from metadata */
    ,open_passthrough= /* provide an alias to produce the
                          CONNECT TO statement for the
                          relevant external database */
    ,sql_options= /* add any options to add to proc sql statement eg outobs=
                      (only valid for pass through) */
    ,mDebug=0
    ,mAbort=0
)/*/STORE SOURCE*/;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing mm_assigndirectlib.sas;
%&mD.put _local_;

%if &mAbort=1 %then %let mAbort=;
%else %let mAbort=%str(*);

%&mD.put NOTE: Creating direct (non META) connection to &libref library;

%local cur_engine;
%let cur_engine=%mf_getengine(&libref);
%if &cur_engine ne META and &cur_engine ne %then %do;
  %put NOTE:  &libref already has a direct (&cur_engine) libname connection;
  %return;
%end;
%else %if %upcase(&libref)=WORK %then %do;
  %put NOTE: We already have a direct connection to WORK :-) ;
  %return;
%end;

/* need to determine the library ENGINE first */
%local engine;
data _null_;
  length lib_uri engine $256;
  call missing (of _all_);
  /* get URI for the particular library */
  rc1=metadata_getnobj("omsobj:SASLibrary?@Libref ='&libref'",1,lib_uri);
  /* get the Engine attribute of the previous object */
  rc2=metadata_getattr(lib_uri,'Engine',engine);
  putlog "mm_assigndirectlib for &libref:" rc1= lib_uri= rc2= engine=;
  call symputx("liburi",lib_uri,'l');
  call symputx("engine",engine,'l');
run;

/* now obtain engine specific connection details */
%if &engine=BASE %then %do;
  %&mD.put NOTE: Retrieving BASE library path;
  data _null_;
    length up_uri $256 path cat_path $1024;
    retain cat_path;
    call missing (of _all_);
    /* get all the filepaths of the UsingPackages association  */
    i=1;
    rc3=metadata_getnasn("&liburi",'UsingPackages',i,up_uri);
    do while (rc3>0);
      /* get the DirectoryName attribute of the previous object */
      rc4=metadata_getattr(up_uri,'DirectoryName',path);
      if i=1 then path = '("'!!trim(path)!!'" ';
      else path =' "'!!trim(path)!!'" ';
      cat_path = trim(cat_path) !! " " !! trim(path) ;
      i+1;
        rc3=metadata_getnasn("&liburi",'UsingPackages',i,up_uri);
    end;
    cat_path = trim(cat_path) !! ")";
    &mD.putlog "NOTE: Getting physical path for &libref library";
    &mD.putlog rc3= up_uri= rc4= cat_path= path=;
    &mD.putlog "NOTE: Libname cmd will be:";
    &mD.putlog "libname &libref" cat_path;
    call symputx("filepath",cat_path,'l');
  run;

  %if %sysevalf(&sysver<9.4) %then %do;
    libname &libref &filepath;
  %end;
  %else %do;
    /* apply the new filelocks option to cater for temporary locks */
    libname &libref &filepath filelockwait=5;
  %end;

%end;
%else %if &engine=REMOTE %then %do;
  data x;
    length rcCon rcProp rc k 3 uriCon uriProp PropertyValue PropertyName
      Delimiter $256 properties $2048;
    retain properties;
    rcCon = metadata_getnasn("&liburi", "LibraryConnection", 1, uriCon);

    rcProp = metadata_getnasn(uriCon, "Properties", 1, uriProp);

    k = 1;
    rcProp = metadata_getnasn(uriCon, "Properties", k, uriProp);
    do while (rcProp > 0);
      rc = metadata_getattr(uriProp , "DefaultValue",PropertyValue);
      rc = metadata_getattr(uriProp , "PropertyName",PropertyName);
      rc = metadata_getattr(uriProp , "Delimiter",Delimiter);
      properties = trim(properties) !! " " !! trim(PropertyName)
        !! trim(Delimiter) !! trim(PropertyValue);
      output;
      k+1;
      rcProp = metadata_getnasn(uriCon, "Properties", k, uriProp);
    end;
    %&mD.put NOTE: Getting properties for REMOTE SHARE &libref library;
    &mD.put _all_;
    %&mD.put NOTE: Libname cmd will be:;
    %&mD.put libname &libref &engine &properties slibref=&libref;
    call symputx ("properties",trim(properties),'l');
  run;

  libname &libref &engine &properties slibref=&libref;

%end;

%else %if &engine=OLEDB %then %do;
  %&mD.put NOTE: Retrieving OLEDB connection details;
  data _null_;
    length domain datasource provider properties schema
      connx_uri domain_uri conprop_uri lib_uri schema_uri value $256.;
    call missing (of _all_);
    /* get source connection ID */
    rc=metadata_getnasn("&liburi",'LibraryConnection',1,connx_uri);
    /* get connection domain */
    rc1=metadata_getnasn(connx_uri,'Domain',1,domain_uri);
    rc2=metadata_getattr(domain_uri,'Name',domain);
    &mD.putlog / 'NOTE: ' // 'NOTE- connection id: ' connx_uri ;
    &mD.putlog 'NOTE- domain: ' domain;
    /* get DSN and PROVIDER from connection properties */
    i=0;
    do until (rc<0);
      i+1;
      rc=metadata_getnasn(connx_uri,'Properties',i,conprop_uri);
      rc2=metadata_getattr(conprop_uri,'Name',value);
      if value='Connection.OLE.Property.DATASOURCE.Name.xmlKey.txt' then do;
        rc3=metadata_getattr(conprop_uri,'DefaultValue',datasource);
      end;
      else if value='Connection.OLE.Property.PROVIDER.Name.xmlKey.txt' then do;
        rc4=metadata_getattr(conprop_uri,'DefaultValue',provider);
      end;
      else if value='Connection.OLE.Property.PROPERTIES.Name.xmlKey.txt' then
      do;
        rc5=metadata_getattr(conprop_uri,'DefaultValue',properties);
      end;
    end;
    &mD.putlog 'NOTE- dsn/provider/properties: ' /
                    datasource provider properties;
    &mD.putlog 'NOTE- schema: ' schema // 'NOTE-';

    /* get SCHEMA */
    rc6=metadata_getnasn("&liburi",'UsingPackages',1,lib_uri);
    rc7=metadata_getattr(lib_uri,'SchemaName',schema);
    call symputx('SQL_domain',domain,'l');
    call symputx('SQL_dsn',datasource,'l');
    call symputx('SQL_provider',provider,'l');
    call symputx('SQL_properties',properties,'l');
    call symputx('SQL_schema',schema,'l');
  run;

  %if %length(&open_passthrough)>0 %then %do;
    proc sql &sql_options;
    connect to OLEDB as &open_passthrough(INSERT_SQL=YES
      /* need additional properties to make this work */
        properties=('Integrated Security'=SSPI
                    'Persist Security Info'=True
                  %sysfunc(compress(%str(&SQL_properties),%str(())))
                  )
      DATASOURCE=&sql_dsn PROMPT=NO
      PROVIDER=&sql_provider SCHEMA=&sql_schema CONNECTION = GLOBAL);
  %end;
  %else %do;
    LIBNAME &libref OLEDB  PROPERTIES=&sql_properties
      DATASOURCE=&sql_dsn  PROVIDER=&sql_provider SCHEMA=&sql_schema
    %if %length(&sql_domain)>0 %then %do;
      authdomain="&sql_domain"
    %end;
      connection=shared;
  %end;
%end;
%else %if &engine=ODBC %then %do;
  &mD.%put NOTE: Retrieving ODBC connection details;
  data _null_;
    length connx_uri conprop_uri value datasource up_uri schema $256.;
    call missing (of _all_);
    /* get source connection ID */
    rc=metadata_getnasn("&liburi",'LibraryConnection',1,connx_uri);
    /* get connection properties */
    i=0;
    do until (rc2<0);
      i+1;
      rc2=metadata_getnasn(connx_uri,'Properties',i,conprop_uri);
      rc3=metadata_getattr(conprop_uri,'Name',value);
      if value='Connection.ODBC.Property.DATASRC.Name.xmlKey.txt' then do;
        rc4=metadata_getattr(conprop_uri,'DefaultValue',datasource);
        rc2=-1;
      end;
    end;
    /* get SCHEMA */
    rc6=metadata_getnasn("&liburi",'UsingPackages',1,up_uri);
    rc7=metadata_getattr(up_uri,'SchemaName',schema);
    &mD.put rc= connx_uri= rc2= conprop_uri= rc3= value= rc4= datasource=
      rc6= up_uri= rc7= schema=;

    call symputx('SQL_schema',schema,'l');
    call symputx('SQL_dsn',datasource,'l');
  run;

  %if %length(&open_passthrough)>0 %then %do;
    proc sql &sql_options;
    connect to ODBC as &open_passthrough
      (INSERT_SQL=YES DATASRC=&sql_dsn. CONNECTION=global);
  %end;
  %else %do;
    libname &libref ODBC DATASRC=&sql_dsn SCHEMA=&sql_schema;
  %end;
%end;
%else %if &engine=POSTGRES %then %do;
  %put NOTE: Obtaining POSTGRES library details;
  data _null_;
    length database ignore_read_only_columns direct_exe preserve_col_names
      preserve_tab_names server schema authdomain user password
      prop name value uri urisrc $256.;
    call missing (of _all_);
    /* get database value */
    prop='Connection.DBMS.Property.DB.Name.xmlKey.txt';
    rc=metadata_getprop("&liburi",prop,database,"");
    if database^='' then database='database='!!quote(trim(database));
    call symputx('database',database,'l');

    /* get IGNORE_READ_ONLY_COLUMNS value */
    prop='Library.DBMS.Property.DBIROC.Name.xmlKey.txt';
    rc=metadata_getprop("&liburi",prop,ignore_read_only_columns,"");
    if ignore_read_only_columns^='' then ignore_read_only_columns=
      'ignore_read_only_columns='!!ignore_read_only_columns;
    call symputx('ignore_read_only_columns',ignore_read_only_columns,'l');

    /* get DIRECT_EXE value */
    prop='Library.DBMS.Property.DirectExe.Name.xmlKey.txt';
    rc=metadata_getprop("&liburi",prop,direct_exe,"");
    if direct_exe^='' then direct_exe='direct_exe='!!direct_exe;
    call symputx('direct_exe',direct_exe,'l');

    /* get PRESERVE_COL_NAMES value */
    prop='Library.DBMS.Property.PreserveColNames.Name.xmlKey.txt';
    rc=metadata_getprop("&liburi",prop,preserve_col_names,"");
    if preserve_col_names^='' then preserve_col_names=
      'preserve_col_names='!!preserve_col_names;
    call symputx('preserve_col_names',preserve_col_names,'l');

    /* get PRESERVE_TAB_NAMES value */
    /* be careful with PRESERVE_TAB_NAMES=YES - it will mean your table will
      become case sensitive!! */
    prop='Library.DBMS.Property.PreserveTabNames.Name.xmlKey.txt';
    rc=metadata_getprop("&liburi",prop,preserve_tab_names,"");
    if preserve_tab_names^='' then preserve_tab_names=
      'preserve_tab_names='!!preserve_tab_names;
    call symputx('preserve_tab_names',preserve_tab_names,'l');

    /* get SERVER value */
    if metadata_getnasn("&liburi","LibraryConnection",1,uri)>0 then do;
      prop='Connection.DBMS.Property.SERVER.Name.xmlKey.txt';
      rc=metadata_getprop(uri,prop,server,"");
    end;
    if server^='' then server='server='!!quote(cats(server));
    call symputx('server',server,'l');

    /* get SCHEMA value */
    if metadata_getnasn("&liburi","UsingPackages",1,uri)>0 then do;
      rc=metadata_getattr(uri,"SchemaName",schema);
    end;
    if schema^='' then schema='schema='!!schema;
    call symputx('schema',schema,'l');

    /* get AUTHDOMAIN value */
    /* this is only useful if the user account contains that auth domain
    if metadata_getnasn("&liburi","DefaultLogin",1,uri)>0 then do;
      rc=metadata_getnasn(uri,"Domain",1,urisrc);
      rc=metadata_getattr(urisrc,"Name",authdomain);
    end;
    if authdomain^='' then authdomain='authdomain='!!quote(trim(authdomain));
    */
    call symputx('authdomain',authdomain,'l');

    /* get user & pass */
    if authdomain='' & metadata_getnasn("&liburi","DefaultLogin",1,uri)>0 then
    do;
      rc=metadata_getattr(uri,"UserID",user);
      rc=metadata_getattr(uri,"Password",password);
    end;
    if user^='' then do;
      user='user='!!quote(trim(user));
      password='password='!!quote(trim(password));
    end;
    call symputx('user',user,'l');
    call symputx('password',password,'l');

    &md.put _all_;
  run;

  %if %length(&open_passthrough)>0 %then %do;
    %put %str(WARN)ING: Passthrough option for postgres not yet supported;
    %return;
  %end;
  %else %do;
    %if &mdebug=1 %then %do;
      %put NOTE: Executing the following:/;
      %put NOTE- libname &libref POSTGRES &database &ignore_read_only_columns;
      %put NOTE-   &direct_exe &preserve_col_names &preserve_tab_names;
      %put NOTE-   &server &schema &authdomain &user &password //;
    %end;
    libname &libref POSTGRES &database &ignore_read_only_columns &direct_exe
      &preserve_col_names &preserve_tab_names &server &schema &authdomain
      &user &password;
  %end;
%end;
%else %if &engine=ORACLE %then %do;
  %put NOTE: Obtaining &engine library details;
  data _null_;
    length assocuri1 assocuri2 assocuri3 authdomain path schema $256;
    call missing (of _all_);

    /* get auth domain */
    rc=metadata_getnasn("&liburi",'LibraryConnection',1,assocuri1);
    rc=metadata_getnasn(assocuri1,'Domain',1,assocuri2);
    rc=metadata_getattr(assocuri2,"Name",authdomain);
    call symputx('authdomain',authdomain,'l');

    /* path */
    rc=metadata_getprop(assocuri1,
      'Connection.Oracle.Property.PATH.Name.xmlKey.txt',path);
    call symputx('path',path,'l');

    /* schema */
    rc=metadata_getnasn("&liburi",'UsingPackages',1,assocuri3);
    rc=metadata_getattr(assocuri3,'SchemaName',schema);
    call symputx('schema',schema,'l');
  run;
  %put NOTE: Executing the following:/; %put NOTE-;
  %put NOTE- libname &libref ORACLE path=&path schema=&schema;
  %put NOTE-     authdomain=&authdomain;
  %put NOTE-;
  libname &libref ORACLE path=&path schema=&schema authdomain=&authdomain;
%end;
%else %if &engine=SQLSVR %then %do;
  %put NOTE: Obtaining &engine library details;
  data _null;
    length assocuri1 assocuri2 assocuri3 authdomain path schema userid
      passwd $256;
    call missing (of _all_);

    rc=metadata_getnasn("&liburi",'DefaultLogin',1,assocuri1);
    rc=metadata_getattr(assocuri1,"UserID",userid);
    rc=metadata_getattr(assocuri1,"Password",passwd);
    call symputx('user',userid,'l');
    call symputx('pass',passwd,'l');

    /* path */
    rc=metadata_getnasn("&liburi",'LibraryConnection',1,assocuri2);
    rc=metadata_getprop(assocuri2,
      'Connection.SQL.Property.Datasrc.Name.xmlKey.txt',path);
    call symputx('path',path,'l');

    /* schema */
    rc=metadata_getnasn("&liburi",'UsingPackages',1,assocuri3);
    rc=metadata_getattr(assocuri3,'SchemaName',schema);
    call symputx('schema',schema,'l');
  run;

  %put NOTE: Executing the following:/; %put NOTE-;
  %put NOTE- libname &libref SQLSVR datasrc=&path schema=&schema ;
  %put NOTE-    user="&user" pass="XXX";
  %put NOTE-;

  libname &libref SQLSVR datasrc=&path schema=&schema user="&user" pass="&pass";
%end;
%else %if &engine=TERADATA %then %do;
  %put NOTE: Obtaining &engine library details;
  data _null;
    length assocuri1 assocuri2 assocuri3 authdomain path schema userid
      passwd $256;
    call missing (of _all_);

        /* get auth domain */
    rc=metadata_getnasn("&liburi",'LibraryConnection',1,assocuri1);
    rc=metadata_getnasn(assocuri1,'Domain',1,assocuri2);
    rc=metadata_getattr(assocuri2,"Name",authdomain);
    call symputx('authdomain',authdomain,'l');

    /*
    rc=metadata_getnasn("&liburi",'DefaultLogin',1,assocuri1);
    rc=metadata_getattr(assocuri1,"UserID",userid);
    rc=metadata_getattr(assocuri1,"Password",passwd);
    call symputx('user',userid,'l');
    call symputx('pass',passwd,'l');
    */

    /* path */
    rc=metadata_getnasn("&liburi",'LibraryConnection',1,assocuri2);
    rc=metadata_getprop(assocuri2,
      'Connection.Teradata.Property.SERVER.Name.xmlKey.txt',path);
    call symputx('path',path,'l');

    /* schema */
    rc=metadata_getnasn("&liburi",'UsingPackages',1,assocuri3);
    rc=metadata_getattr(assocuri3,'SchemaName',schema);
    call symputx('schema',schema,'l');
  run;

  %put NOTE: Executing the following:/; %put NOTE-;
  %put NOTE- libname &libref TERADATA server="&path" schema=&schema ;
  %put NOTe-   authdomain=&authdomain;
  %put NOTE-;

  libname &libref TERADATA server="&path" schema=&schema authdomain=&authdomain;
%end;
%else %if &engine= %then %do;
  %put NOTE: Libref &libref is not registered in metadata;
  %&mAbort.mp_abort(
    msg=%str(ERR)OR: Libref &libref is not registered in metadata
    ,mac=mm_assigndirectlib.sas);
  %return;
%end;
%else %do;
  %put %str(WARN)ING: Engine &engine is currently unsupported;
  %put %str(WARN)ING- Please contact your support team.;
  %return;
%end;

%mend mm_assigndirectlib;
/**
  @file
  @brief Assigns a meta engine library using LIBREF
  @details Queries metadata to get the library NAME which can then be used in
    a libname statement with the meta engine.

  usage:

      %macro mp_abort(iftrue,mac,msg);%put &=msg;%mend;

      %mm_assignlib(SOMEREF)

  <h4> SAS Macros </h4>
  @li mp_abort.sas

  @param libref the libref (not name) of the metadata library
  @param mAbort= If not assigned, HARD will call %mp_abort(), SOFT will
    silently return

  @returns libname statement

  @version 9.2
  @author Allan Bowe

**/

%macro mm_assignlib(
    libref
    ,mAbort=HARD
)/*/STORE SOURCE*/;

%if %sysfunc(libref(&libref)) %then %do;
  %local mp_abort msg; %let mp_abort=0;
  data _null_;
    length liburi LibName $200;
    call missing(of _all_);
    nobj=metadata_getnobj("omsobj:SASLibrary?@Libref='&libref'",1,liburi);
    if nobj=1 then do;
      rc=metadata_getattr(liburi,"Name",LibName);
      /* now try and assign it */
      if libname("&libref",,'meta',cats('liburi="',liburi,'";')) ne 0 then do;
        putlog "&libref could not be assigned";
        call symputx('msg',sysmsg(),'l');
        if "&mabort"='HARD' then call symputx('mp_abort',1,'l');
      end;
      else do;
        put (_all_)(=);
        call symputx('libname',libname,'L');
        call symputx('liburi',liburi,'L');
      end;
    end;
    else if nobj>1 then do;
      if "&mabort"='HARD' then call symputx('mp_abort',1);
      call symputx('msg',"More than one library with libref=&libref");
    end;
    else do;
      if "&mabort"='HARD' then call symputx('mp_abort',1);
      call symputx('msg',"Library &libref not found in metadata");
    end;
  run;

  %if &mp_abort=1 %then %do;
    %mp_abort(iftrue= (&mp_abort=1)
      ,mac=&sysmacroname
      ,msg=&msg
    )
    %return;
  %end;
  %else %if %length(&msg)>2 %then %do;
    %put NOTE: &msg;
    %return;
  %end;

%end;
%else %do;
  %put NOTE: Library &libref is already assigned;
%end;
%mend mm_assignlib;
/**
  @file
  @brief Create an Application object in a metadata folder
  @details Application objects are useful for storing properties in metadata.
    This macro is idempotent - it will not create an object with the same name
    in the same location, twice.

  usage:

      %mm_createapplication(tree=/User Folders/sasdemo
        ,name=MyApp
        ,classidentifier=myAppSeries
        ,params= name1=value1&#x0a;name2=value2&#x0a;emptyvalue=
      )

  @warning application components do not get deleted when removing the container
  folder!  be sure you have the administrative priviliges to remove this kind of
  metadata from the SMC plugin (or be ready to do to so programmatically).

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_verifymacvars.sas

  @param tree= The metadata folder uri, or the metadata path, in which to
    create the object.  This must exist.
  @param name= Application object name.  Avoid spaces.
  @param ClassIdentifier= the class of applications to which this app belongs
  @param params= name=value pairs which will become public properties of the
    application object. These are delimited using &#x0a; (newline character)

  @param desc= Application description (optional).  Avoid ampersands as these
    are illegal characters (unless they are escapted- eg &amp;)
  @param version= version number of application
  @param frefin= fileref to use (enables change if there is a conflict).  The
    filerefs are left open, to enable inspection after running the
    macro (or importing into an xmlmap if needed).
  @param frefout= fileref to use (enables change if there is a conflict)
  @param mDebug= set to 1 to show debug messages in the log

  @author Allan Bowe

**/

%macro mm_createapplication(
    tree=/User Folders/sasdemo
    ,name=myApp
    ,ClassIdentifier=mcore
    ,desc=Created by mm_createapplication
    ,params= param1=1&#x0a;param2=blah
    ,version=
    ,frefin=mm_in
    ,frefout=mm_out
    ,mDebug=1
    );

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing &sysmacroname..sas;
%&mD.put _local_;

%mf_verifymacvars(tree name)

/**
  * check tree exists
  */

data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&tree","Folder",type,uri);
  call symputx('type',type,'l');
  call symputx('treeuri',uri,'l');
run;

%mp_abort(
  iftrue= (&type ne Tree)
  ,mac=mm_createapplication.sas
  ,msg=Tree &tree does not exist!
)

/**
  * Check object does not exist already
  */
data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&tree/&name","Application",type,uri);
  call symputx('type',type,'l');
  putlog (_all_)(=);
run;

%mp_abort(
  iftrue= (&type = SoftwareComponent)
  ,mac=mm_createapplication.sas
  ,msg=Application &name already exists in &tree!
)


/**
  * Now we can create the application
  */
filename &frefin temp;

/* write header XML */
data _null_;
  file &frefin;
  name=quote(symget('name'));
  desc=quote(symget('desc'));
  ClassIdentifier=quote(symget('ClassIdentifier'));
  version=quote(symget('version'));
  params=quote(symget('params'));
  treeuri=quote(symget('treeuri'));

  put "<AddMetadata><Reposid>$METAREPOSITORY</Reposid><Metadata> "/
    '<SoftwareComponent IsHidden="0" Name=' name ' ProductName=' name /
    '  ClassIdentifier=' ClassIdentifier ' Desc=' desc /
    '  SoftwareVersion=' version '  SpecVersion=' version /
    '  Major="1" Minor="1" UsageVersion="1000000" PublicType="Application" >' /
    '  <Notes>' /
    '    <TextStore Name="Public Configuration Properties" IsHidden="0" ' /
    '       UsageVersion="0" StoredText=' params '/>' /
    '  </Notes>' /
    "<Trees><Tree ObjRef=" treeuri "/></Trees>"/
    "</SoftwareComponent></Metadata><NS>SAS</NS>"/
    "<Flags>268435456</Flags></AddMetadata>";
run;

filename &frefout temp;

proc metadata in= &frefin out=&frefout verbose;
run;

%if &mdebug=1 %then %do;
  /* write the response to the log for debugging */
  data _null_;
    infile &frefout lrecl=1048576;
    input;
    put _infile_;
  run;
%end;

%put NOTE: Checking to ensure application (&name) was created;
data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&tree/&name","Application",type,uri);
  call symputx('apptype',type,'l');
  %if &mdebug=1 %then putlog (_all_)(=);;
run;
%if &apptype ne SoftwareComponent %then %do;
  %put %str(ERR)OR: Could not find (&name) at (&tree)!!;
  %return;
%end;
%else %put NOTE: Application (&name) successfully created in (&tree)!;


%mend mm_createapplication;/**
  @file mm_createdataset.sas
  @brief Create a dataset from a metadata definition
  @details This macro was built to support viewing empty tables in
    https://datacontroller.io - a free evaluation copy is available by
    contacting the author (Allan Bowe).

    The table can be retrieved using LIBRARY.DATASET reference, or directly
    using the metadata URI.

    The dataset is written to the WORK library.

  usage:

    %mm_createdataset(libds=metlib.some_dataset)

    or

    %mm_createdataset(tableuri=G5X8AFW1.BE00015Y)

  <h4> SAS Macros </h4>
  @li mm_getlibs.sas
  @li mm_gettables.sas
  @li mm_getcols.sas

  @param libds= library.dataset metadata source.  Note - table names in metadata
    can be longer than 32 chars (just fyi, not an issue here)
  @param tableuri= Metadata URI of the table to be created
  @param outds= The dataset to create, default is `work.mm_createdataset`.
    The table name needs to be 32 chars or less as per SAS naming rules.
  @param mdebug= set DBG to 1 to disable DEBUG messages

  @version 9.4
  @author Allan Bowe

**/

%macro mm_createdataset(libds=,tableuri=,outds=work.mm_createdataset,mDebug=0);
%local dbg errorcheck tempds1 tempds2 tempds3;
%if &mDebug=0 %then %let dbg=*;
%let errorcheck=1;

%if %index(&libds,.)>0 %then %do;
  /* get lib uri */
  data;run;%let tempds1=&syslast;
  %mm_getlibs(outds=&tempds1)
  data _null_;
    set &tempds1;
    if upcase(libraryref)="%upcase(%scan(&libds,1,.))";
    call symputx('liburi',LibraryId,'l');
  run;
  /* get ds uri */
  data;run;%let tempds2=&syslast;
  %mm_gettables(uri=&liburi,outds=&tempds2)
  data _null_;
    set &tempds2;
    if upcase(tablename)="%upcase(%scan(&libds,2,.))";
    call symputx('tableuri',tableuri);
  run;
%end;

data;run;%let tempds3=&syslast;
%mm_getcols(tableuri=&tableuri,outds=&tempds3)

data _null_;
  set &tempds3 end=last;
  if _n_=1 then call execute('data &outds;');
  length attrib $32767;

  if SAScolumntype='C' then type='$';
  attrib='attrib '!!cats(colname)!!' length='!!cats(type,SASColumnLength,'.');

  if not missing(sasformat) then fmt=' format='!!cats(sasformat);
  if not missing(sasinformat) then infmt=' informat='!!cats(sasinformat);
  if not missing(coldesc) then desc=' label='!!quote(cats(coldesc));

  attrib=trim(attrib)!!fmt!!infmt!!desc!!';';

  call execute(attrib);
  if last then call execute('call missing(of _all_);stop;run;');
run;

%mend mm_createdataset;/**
  @file
  @brief Create a Document object in a metadata folder
  @details Document objects are useful for storing properties in metadata.
    This macro is idempotent - it will not create an object with the same name
    in the same location, twice.
    Note - the filerefs are left open, to enable inspection after running the
    macro (or importing into an xmlmap if needed).

  usage:

      %mm_createdocument(tree=/User Folders/sasdemo
        ,name=MyNote)

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_verifymacvars.sas


  @param tree= The metadata folder uri, or the metadata path, in which to
    create the document.  This must exist.
  @param name= Document object name.  Avoid spaces.

  @param desc= Document description (optional)
  @param textrole= TextRole property (optional)
  @param frefin= fileref to use (enables change if there is a conflict)
  @param frefout= fileref to use (enables change if there is a conflict)
  @param mDebug= set to 1 to show debug messages in the log

  @author Allan Bowe

**/

%macro mm_createdocument(
    tree=/User Folders/sasdemo
    ,name=myNote
    ,desc=Created by &sysmacroname
    ,textrole=
    ,frefin=mm_in
    ,frefout=mm_out
    ,mDebug=1
    );

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing &sysmacroname..sas;
%&mD.put _local_;

%mf_verifymacvars(tree name)

/**
  * check tree exists
  */

data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&tree","Folder",type,uri);
  call symputx('type',type,'l');
  call symputx('treeuri',uri,'l');
run;

%mp_abort(
  iftrue= (&type ne Tree)
  ,mac=mm_createdocument.sas
  ,msg=Tree &tree does not exist!
)

/**
  * Check object does not exist already
  */
data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&tree/&name","Note",type,uri);
  call symputx('type',type,'l');
  call symputx('docuri',uri,'l');
  putlog (_all_)(=);
run;

%if &type = Document %then %do;
  %put Document &name already exists in &tree!;
  %return;
%end;

/**
  * Now we can create the document
  */
filename &frefin temp;

/* write header XML */
data _null_;
  file &frefin;
  name=quote("&name");
  desc=quote("&desc");
  textrole=quote("&textrole");
  treeuri=quote("&treeuri");

  put "<AddMetadata><Reposid>$METAREPOSITORY</Reposid>"/
    '<Metadata><Document IsHidden="0" PublicType="Note" UsageVersion="1000000"'/
    "  Name=" name " desc=" desc " TextRole=" textrole ">"/
    "<Notes> "/
    '  <TextStore IsHidden="0"  Name=' name ' UsageVersion="0" '/
    '    TextRole="SourceCode" StoredText="hello world" />' /
    '</Notes>'/
    /*URI="Document for public note" */
    "<Trees><Tree ObjRef=" treeuri "/></Trees>"/
    "</Document></Metadata><NS>SAS</NS>"/
    "<Flags>268435456</Flags></AddMetadata>";
run;

filename &frefout temp;

proc metadata in= &frefin out=&frefout verbose;
run;

%if &mdebug=1 %then %do;
  /* write the response to the log for debugging */
  data _null_;
    infile &frefout lrecl=1048576;
    input;
    put _infile_;
  run;
%end;

%mend mm_createdocument;/**
  @file
  @brief Recursively create a metadata folder
  @details This macro was inspired by Paul Homes who wrote an early
    version (mkdirmd.sas) in 2010. The original is described here:
    https://platformadmin.com/blogs/paul/2010/07/mkdirmd/

    The macro will NOT create a new ROOT folder - not
    because it can't, but more because that is generally not something
    your administrator would like you to do!

    The macro is idempotent - if you run it twice, it will only create a folder
    once.

  usage:

      %mm_createfolder(path=/some/meta/folder)

  @param [in] path= Name of the folder to create.
  @param [in] mdebug= set DBG to 1 to disable DEBUG messages

  @version 9.4
  @author Allan Bowe

**/

%macro mm_createfolder(path=,mDebug=0);
%put &sysmacroname: execution started for &path;
%local dbg errorcheck;
%if &mDebug=0 %then %let dbg=*;

%local parentFolderObjId child errorcheck paths;
%let paths=0;
%let errorcheck=1;

%if &syscc ge 4 %then %do;
  %put SYSCC=&syscc - this macro requires a clean session;
  %return;
%end;

data _null_;
  length objId parentId objType parent child $200
    folderPath $1000;
  call missing (of _all_);
  folderPath = "%trim(&path)";

  * remove any trailing slash ;
  if ( substr(folderPath,length(folderPath),1) = '/' ) then
    folderPath=substr(folderPath,1,length(folderPath)-1);

  * name must not be blank;
  if ( folderPath = '' ) then do;
    put "%str(ERR)OR: &sysmacroname PATH parameter value must be non-blank";
  end;

  * must have a starting slash ;
  if ( substr(folderPath,1,1) ne '/' ) then do;
    put "%str(ERR)OR: &sysmacroname PATH param value must have starting slash";
    stop;
  end;

  * check if folder already exists ;
  rc=metadata_pathobj('',cats(folderPath,"(Folder)"),"",objType,objId);
  if rc ge 1 then do;
    put "NOTE: Folder " folderPath " already exists!";
    stop;
  end;

  * do not create a root (one level) folder ;
  if countc(folderPath,'/')=1 then do;
    put "%str(ERR)OR: &sysmacroname will not create a new ROOT folder";
    stop;
  end;

  * check that root folder exists ;
  root=cats('/',scan(folderpath,1,'/'),"(Folder)");
  if metadata_pathobj('',root,"",objType,parentId)<1 then do;
    put "%str(ERR)OR: " root " does not exist!";
    stop;
  end;

  * check that parent folder exists ;
  child=scan(folderPath,-1,'/');
  parent=substr(folderpath,1,length(folderpath)-length(child)-1);
  rc=metadata_pathobj('',cats(parent,"(Folder)"),"",objType,parentId);
  if rc<1 then do;
    putlog 'The following folders will be created:';
    /* folder does not exist - so start from top and work down */
    length newpath $1000;
    paths=0;
    do x=2 to countw(folderpath,'/');
      newpath='';
      do i=1 to x;
        newpath=cats(newpath,'/',scan(folderpath,i,'/'));
      end;
      rc=metadata_pathobj('',cats(newpath,"(Folder)"),"",objType,parentId);
      if rc<1 then do;
        paths+1;
        call symputx(cats('path',paths),newpath);
        putlog newpath;
      end;
      call symputx('paths',paths);
    end;
  end;
  else putlog "parent " parent " exists";

  call symputx('parentFolderObjId',parentId,'l');
  call symputx('child',child,'l');
  call symputx('errorcheck',0,'l');

  &dbg put (_all_)(=);
run;

%if &errorcheck=1 or &syscc ge 4 %then %return;

%if &paths>0 %then %do x=1 %to &paths;
  %put executing recursive call for &&path&x;
  %mm_createfolder(path=&&path&x)
%end;
%else %do;
  filename __newdir temp;
  options noquotelenmax;
  %local inmeta;
  %put creating: &path;
  %let inmeta=<AddMetadata><Reposid>$METAREPOSITORY</Reposid><Metadata>
    <Tree Name='&child' PublicType='Folder' TreeType='BIP Folder'
    UsageVersion='1000000'><ParentTree><Tree ObjRef='&parentFolderObjId'/>
    </ParentTree></Tree></Metadata><NS>SAS</NS><Flags>268435456</Flags>
    </AddMetadata>;

  proc metadata in="&inmeta" out=__newdir verbose;
  run ;

  /* check it was successful */
  data _null_;
    length objId parentId objType parent child $200 ;
    call missing (of _all_);
    rc=metadata_pathobj('',cats("&path","(Folder)"),"",objType,objId);
    if rc ge 1 then do;
      putlog "SUCCCESS!  &path created.";
    end;
    else do;
      putlog "%str(ERR)OR: unsuccessful attempt to create &path";
      call symputx('syscc',8);
    end;
  run;

  /* write the response to the log for debugging */
  %if &mDebug ne 0 %then %do;
    data _null_;
      infile __newdir lrecl=32767;
      input;
      put _infile_;
    run;
  %end;
  filename __newdir clear;
%end;

%put &sysmacroname: execution finished for &path;
%mend mm_createfolder;/**
  @file
  @brief Create a SAS Library
  @details Currently only supports BASE engine

    This macro is idempotent - if you run it twice (for the same libref or
    libname), it will only create one library.  There is a dependency on other
    macros in this library - they should be installed as a suite (see README).

  Usage:

      %mm_createlibrary(
        libname=My New Library
        ,libref=mynewlib
        ,libdesc=Super & <fine>
        ,engine=BASE
        ,tree=/User Folders/sasdemo
        ,servercontext=SASApp
        ,directory=/tmp/tests
        ,mDebug=1)

  <h4> SAS Macros </h4>
  @li mf_verifymacvars.sas
  @li mm_createfolder.sas


  @param libname= Library name (as displayed to user, 256 chars). Duplicates
    are not created (case sensitive).
  @param libref= Library libref (8 chars).  Duplicate librefs are not created,
    HOWEVER- the check is not case sensitive - if *libref* exists, *LIBREF*
    will still be created.   Librefs created will always be uppercased.
  @param engine= Library engine (currently only BASE supported)
  @param tree= The metadata folder uri, or the metadata path, in which to
    create the library.
  @param servercontext= The SAS server against which the library is registered.
  @param IsPreassigned= set to 1 if the library should be pre-assigned.

  @param libdesc= Library description (optional)
  @param directory= Required for the BASE engine. The metadata directory objects
    are searched to find an existing one with a matching physical path.
    If more than one uri found with that path, then the first one will be used.
    If no URI is found, a new directory object will be created.  The physical
    path will also be created, if it doesn't exist.


  @param mDebug= set to 1 to show debug messages in the log
  @param frefin= fileref to use (enables change if there is a conflict).  The
    filerefs are left open, to enable inspection after running the
    macro (or importing into an xmlmap if needed).
  @param frefout= fileref to use (enables change if there is a conflict)


  @version 9.3
  @author Allan Bowe

**/

%macro mm_createlibrary(
    libname=My New Library
    ,libref=mynewlib
    ,libdesc=Created automatically using the mm_createlibrary macro
    ,engine=BASE
    ,tree=/User Folders/sasdemo
    ,servercontext=SASApp
    ,directory=/tmp/somelib
    ,IsPreassigned=0
    ,mDebug=0
    ,frefin=mm_in
    ,frefout=mm_out
)/*/STORE SOURCE*/;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing &sysmacroname..sas;
%&mD.put _local_;

%let libref=%upcase(&libref);

/**
  * Check Library does not exist already with this libname
  */
data _null_;
  length type uri $256;
  rc=metadata_resolve("omsobj:SASLibrary?@Name='&libname'",type,uri);
  call symputx('checktype',type,'l');
  call symputx('liburi',uri,'l');
  putlog (_all_)(=);
run;
%if &checktype = SASLibrary %then %do;
  %put %str(WARN)ING: Library (&liburi) already exists with libname (&libname);
  %return;
%end;

/**
  * Check Library does not exist already with this libref
  */
data _null_;
  length type uri $256;
  rc=metadata_resolve("omsobj:SASLibrary?@Libref='&libref'",type,uri);
  call symputx('checktype',type,'l');
  call symputx('liburi',uri,'l');
  putlog (_all_)(=);
run;
%if &checktype = SASLibrary %then %do;
  %put %str(WARN)ING: Library (&liburi) already exists with libref (&libref)  ;
  %return;
%end;


/**
  * Attempt to create tree
  */
%mm_createfolder(path=&tree)

/**
  * check tree exists
  */
data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&tree","Folder",type,uri);
  call symputx('foldertype',type,'l');
  call symputx('treeuri',uri,'l');
run;
%if &foldertype ne Tree %then %do;
  %put %str(WARN)ING: Tree &tree does not exist!;
  %return;
%end;

/**
  * Create filerefs for proc metadata call
  */
filename &frefin temp;
filename &frefout temp;

%if &engine=BASE %then %do;

  %mf_verifymacvars(libname libref engine servercontext tree)



  /**
    * Check that the ServerContext exists
    */
  data _null_;
    length type uri $256;
    rc=metadata_resolve("omsobj:ServerContext?@Name='&ServerContext'",type,uri);
    call symputx('checktype',type,'l');
    call symputx('serveruri',uri,'l');
    putlog (_all_)(=);
  run;
  %if &checktype ne ServerContext %then %do;
    %put %str(ERR)OR: ServerContext (&ServerContext) does not exist!;
    %return;
  %end;

  /**
    * Get prototype info
    */
  data _null_;
    length type uri str $256;
    str="omsobj:Prototype?@Name='Library.SAS.Prototype.Name.xmlKey.txt'";
    rc=metadata_resolve(str,type,uri);
    call symputx('checktype',type,'l');
    call symputx('prototypeuri',uri,'l');
    putlog (_all_)(=);
  run;
  %if &checktype ne Prototype %then %do;
    %put %str(ERR)OR: Prototype Library.SAS.Prototype.Name.xmlKey.txt not found;
    %return;
  %end;

  /**
    * Check that Physical location exists
    */
  %if %sysfunc(fileexist(&directory))=0 %then %do;
    %put %str(ERR)OR: Physical directory (&directory) does not appear to exist!;
    %return;
  %end;

  /**
    * Check that Directory Object exists in metadata
    */
  data _null_;
    length type uri $256;
    rc=metadata_resolve("omsobj:Directory?@DirectoryRole='LibraryPath'"
      !!" and @DirectoryName='&directory'",type,uri);
    call symputx('checktype',type,'l');
    call symputx('directoryuri',uri,'l');
    putlog (_all_)(=);
  run;
  %if &checktype ne Directory %then %do;
    %put NOTE: Directory object does not exist for (&directory) location;
    %put NOTE: It will now be created;

    data _null_;
      file &frefin;
      directory=quote(symget('directory'));
      put "<AddMetadata><Reposid>$METAREPOSITORY</Reposid><Metadata> "/
      '<Directory UsageVersion="1000000" IsHidden="0" IsRelative="0"'/
      '  DirectoryRole="LibraryPath" Name="Path" DirectoryName=' directory '/>'/
      "</Metadata><NS>SAS</NS>"/
      "<Flags>268435456</Flags></AddMetadata>";
    run;

    proc metadata in= &frefin out=&frefout %if &mdebug=1 %then verbose;;
    run;
    %if &mdebug=1 %then %do;
      data _null_;
        infile &frefout lrecl=1048576;
        input; put _infile_;
      run;
    %end;
    %put NOTE: Checking to ensure directory (&directory) object was created;
    data _null_;
      length type uri $256;
      rc=metadata_resolve("omsobj:Directory?@DirectoryRole='LibraryPath'"
        !!" and @DirectoryName='&directory'",type,uri);
      call symputx('checktype2',type,'l');
      call symputx('directoryuri',uri,'l');
      %if &mdebug=1 %then putlog (_all_)(=);;
    run;
    %if &checktype2 ne Directory %then %do;
      %put %str(ERR)OR: Directory (&directory) object was NOT created!;
      %return;
    %end;
    %else %put NOTE: Directory (&directoryuri) successfully created!;
  %end;

  /**
    *  check SAS version
    */
  %if %sysevalf(&sysver lt 9.3) %then %do;
    %put %str(WARN)ING: Version 9.3 or later required;
    %return;
  %end;

  /**
    * Prepare the XML and create the library
    */
  data _null_;
    file &frefin;
    treeuri=quote(symget('treeuri'));
    serveruri=quote(symget('serveruri'));
    directoryuri=quote(symget('directoryuri'));
    libname=quote(symget('libname'));
    libref=quote(symget('libref'));
    IsPreassigned=quote(symget('IsPreassigned'));
    prototypeuri=quote(symget('prototypeuri'));

    /* escape description so it can be stored as XML */
    libdesc=tranwrd(symget('libdesc'),'&','&amp;');
    libdesc=tranwrd(libdesc,'<','&lt;');
    libdesc=tranwrd(libdesc,'>','&gt;');
    libdesc=tranwrd(libdesc,"'",'&apos;');
    libdesc=tranwrd(libdesc,'"','&quot;');
    libdesc=tranwrd(libdesc,'0A'x,'&#10;');
    libdesc=tranwrd(libdesc,'0D'x,'&#13;');
    libdesc=tranwrd(libdesc,'$','&#36;');
    libdesc=quote(trim(libdesc));

    put "<AddMetadata><Reposid>$METAREPOSITORY</Reposid><Metadata> "/
        '<SASLibrary Desc=' libdesc ' Engine="BASE" IsDBMSLibname="0" '/
        '  IsHidden="0" IsPreassigned=' IsPreassigned ' Libref=' libref /
        '  UsageVersion="1000000" PublicType="Library" name=' libname '>'/
        '  <DeployedComponents>'/
        '    <ServerContext ObjRef=' serveruri "/>"/
        '  </DeployedComponents>'/
        '  <PropertySets>'/
        '    <PropertySet Name="ModifiedByProductPropertySet" '/
        '      SetRole="ModifiedByProductPropertySet" UsageVersion="0" />'/
        '  </PropertySets>'/
        "  <Trees><Tree ObjRef=" treeuri "/></Trees>"/
        '  <UsingPackages> '/
        '    <Directory ObjRef=' directoryuri ' />'/
        '  </UsingPackages>'/
        '  <UsingPrototype>'/
        '    <Prototype ObjRef=' prototypeuri '/>'/
        '  </UsingPrototype>'/
        '</SASLibrary></Metadata><NS>SAS</NS>'/
        '<Flags>268435456</Flags></AddMetadata>';
  run;


  proc metadata in= &frefin out=&frefout %if &mdebug=1 %then verbose ;;
  run;

  %if &mdebug=1 %then %do;
    data _null_;
      infile &frefout lrecl=1048576;
      input;put _infile_;
    run;
  %end;
  %put NOTE: Checking to ensure library (&libname) was created;
  data _null_;
    length type uri $256;
    rc=metadata_pathobj("","&tree/&libname","Library",type,uri);
    call symputx('libtype',type,'l');
    call symputx('liburi',uri,'l');
    %if &mdebug=1 %then putlog (_all_)(=);;
  run;
  %if &libtype ne SASLibrary %then %do;
    %put %str(ERR)OR: Could not find (&libname) at (&tree)!!;
    %return;
  %end;
  %else %put NOTE: Library (&libname) successfully created in (&tree)!;
%end;
%else %do;
  %put %str(ERR)OR: Other library engine types are not yet supported!!;
%end;


/**
  * Wrap up
  */
%if &mdebug ne 1 %then %do;
  filename &frefin clear;
  filename &frefout clear;
%end;

%mend mm_createlibrary;
/**
  @file
  @brief Create a type 1 Stored Process (9.2 compatible)
  @details This macro creates a Type 1 stored process, and also the necessary
    PromptGroup / File / TextStore objects.  It requires the location (or uri)
    for the App Server / Directory / Folder (Tree) objects.
    To upgrade this macro to work with type 2 (which can embed SAS code
    and is compabitible with SAS from 9.3 onwards) then the UsageVersion should
    change to 2000000 and the TextStore object updated.  The ComputeServer
    reference will also be to ServerContext rather than LogicalServer.

    This macro is idempotent - if you run it twice, it will only create an STP
    once.

  usage (type 1 STP):

      %mm_createstp(stpname=MyNewSTP
        ,filename=mySpecialProgram.sas
        ,directory=SASEnvironment/SASCode/STPs
        ,tree=/User Folders/sasdemo
        ,outds=work.uris)

  If you wish to remove the new STP you can do so by running:

      data _null_;
        set work.uris;
        rc1 = METADATA_DELOBJ(texturi);
        rc2 = METADATA_DELOBJ(prompturi);
        rc3 = METADATA_DELOBJ(fileuri);
        rc4 = METADATA_DELOBJ(stpuri);
        putlog (_all_)(=);
      run;

  usage (type 2 STP):
      %mm_createstp(stpname=MyNewType2STP
        ,filename=mySpecialProgram.sas
        ,directory=SASEnvironment/SASCode/STPs
        ,tree=/User Folders/sasdemo
        ,Server=SASApp
        ,stptype=2)

  <h4> SAS Macros </h4>
  @li mf_nobs.sas
  @li mf_verifymacvars.sas
  @li mm_getdirectories.sas
  @li mm_updatestpsourcecode.sas
  @li mp_dropmembers.sas
  @li mm_getservercontexts.sas

  @param stpname= Stored Process name.  Avoid spaces - testing has shown that
    the check to avoid creating multiple STPs in the same folder with the same
    name does not work when the name contains spaces.
  @param stpdesc= Stored Process description (optional)
  @param filename= the name of the .sas program to run
  @param directory= The directory uri, or the actual path to the sas program
    (no trailing slash).  If more than uri is found with that path, then the
    first one will be used.
  @param tree= The metadata folder uri, or the metadata path, in which to
    create the STP.
  @param server= The server which will run the STP.  Server name or uri is fine.
  @param outds= The two level name of the output dataset.  Will contain all the
    meta uris. Defaults to work.mm_createstp.
  @param mDebug= set to 1 to show debug messages in the log
  @param stptype= Default is 1 (STP code saved on filesystem).  Set to 2 if
    source code is to be saved in metadata (9.3 and above feature).
  @param minify= set to YES to strip comments / blank lines etc
  @param frefin= fileref to use (enables change if there is a conflict).  The
    filerefs are left open, to enable inspection after running the
    macro (or importing into an xmlmap if needed).
  @param frefout= fileref to use (enables change if there is a conflict)
  @param repo= ServerContext is tied to a repo, if you are not using the
    foundation repo then select a different one here

  @returns outds  dataset containing the following columns:
    - stpuri
    - prompturi
    - fileuri
    - texturi

  @version 9.2
  @author Allan Bowe

**/

%macro mm_createstp(
    stpname=Macro People STP
    ,stpdesc=This stp was created automatically by the mm_createstp macro
    ,filename=mm_createstp.sas
    ,directory=SASEnvironment/SASCode
    ,tree=/User Folders/sasdemo
    ,package=false
    ,streaming=true
    ,outds=work.mm_createstp
    ,mDebug=0
    ,server=SASApp
    ,stptype=1
    ,minify=NO
    ,frefin=mm_in
    ,frefout=mm_out
)/*/STORE SOURCE*/;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing mm_CreateSTP.sas;
%&mD.put _local_;

%mf_verifymacvars(stpname filename directory tree)
%mp_dropmembers(%scan(&outds,2,.))

/**
  * check tree exists
  */
data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&tree","Folder",type,uri);
  call symputx('foldertype',type,'l');
  call symputx('treeuri',uri,'l');
run;
%if &foldertype ne Tree %then %do;
  %put %str(WARN)ING: Tree &tree does not exist!;
  %return;
%end;

/**
  * Check STP does not exist already
  */
%local cmtype;
data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&tree/&stpname",'StoredProcess',type,uri);
  call symputx('cmtype',type,'l');
  call symputx('stpuri',uri,'l');
run;
%if &cmtype = ClassifierMap %then %do;
  %put %str(WARN)ING: Stored Process &stpname already exists in &tree!;
  %return;
%end;

/**
  * Check that the physical file exists
  */
%if %sysfunc(fileexist(&directory/&filename)) ne 1 %then %do;
  %put %str(WARN)ING: FILE *&directory/&filename* NOT FOUND!;
  %return;
%end;

%if &stptype=1 %then %do;
  /* type 1 STP - where code is stored on filesystem */
  %if %sysevalf(&sysver lt 9.2) %then %do;
    %put %str(WARN)ING: Version 9.2 or later required;
    %return;
  %end;

  /* check directory object (where 9.2 source code reference is stored) */
  data _null_;
    length id $20 dirtype $256;
    rc=metadata_resolve("&directory",dirtype,id);
    call symputx('checkdirtype',dirtype,'l');
  run;

  %if &checkdirtype ne Directory %then %do;
    %mm_getdirectories(path=&directory,outds=&outds ,mDebug=&mDebug)
    %if %mf_nobs(&outds)=0 or %sysfunc(exist(&outds))=0 %then %do;
      %put %str(WARN)ING: The directory object does not exist for &directory;
      %return;
    %end;
  %end;
  %else %do;
    data &outds;
      directoryuri="&directory";
    run;
  %end;

  data &outds (keep=stpuri prompturi fileuri texturi);
    length stpuri prompturi fileuri texturi serveruri $256 ;
    set &outds;

    /* final checks on uris */
    length id $20 type $256;
    __rc=metadata_resolve("&treeuri",type,id);
    if type ne 'Tree' then do;
      putlog "%str(WARN)ING:  Invalid tree URI: &treeuri";
      stopme=1;
    end;
    __rc=metadata_resolve(directoryuri,type,id);
    if type ne 'Directory' then do;
      putlog "%str(WARN)ING:  Invalid directory URI: " directoryuri;
      stopme=1;
    end;

  /* get server info */
    __rc=metadata_resolve("&server",type,serveruri);
    if type ne 'LogicalServer' then do;
      __rc=metadata_getnobj("omsobj:LogicalServer?@Name='&server'",1,serveruri);
      if serveruri='' then do;
        putlog "%str(WARN)ING:  Invalid server: &server";
        stopme=1;
      end;
    end;

    if stopme=1 then do;
      putlog (_all_)(=);
      stop;
    end;

    /* create empty prompt */
    rc1=METADATA_NEWOBJ('PromptGroup',prompturi,'Parameters');
    rc2=METADATA_SETATTR(prompturi, 'UsageVersion', '1000000');
    rc3=METADATA_SETATTR(prompturi, 'GroupType','2');
    rc4=METADATA_SETATTR(prompturi, 'Name','Parameters');
    rc5=METADATA_SETATTR(prompturi, 'PublicType','Embedded:PromptGroup');
    GroupInfo=
      "<PromptGroup promptId='PromptGroup_%sysfunc(datetime())_&sysprocessid'"
      !!" version='1.0'><Label><Text xml:lang='en-GB'>Parameters</Text>"
      !!"</Label></PromptGroup>";
    rc6 = METADATA_SETATTR(prompturi, 'GroupInfo',groupinfo);

    if sum(of rc1-rc6) ne 0 then do;
      putlog "%str(WARN)ING: Issue creating prompt.";
      if prompturi ne . then do;
        putlog '  Removing orphan: ' prompturi;
        rc = METADATA_DELOBJ(prompturi);
        put rc=;
      end;
      stop;
    end;

    /* create a file uri */
    rc7=METADATA_NEWOBJ('File',fileuri,'SP Source File');
    rc8=METADATA_SETATTR(fileuri, 'FileName',"&filename");
    rc9=METADATA_SETATTR(fileuri, 'IsARelativeName','1');
    rc10=METADATA_SETASSN(fileuri, 'Directories','MODIFY',directoryuri);
    if sum(of rc7-rc10) ne 0 then do;
      putlog "%str(WARN)ING: Issue creating file.";
      if fileuri ne . then do;
        putlog '  Removing orphans:' prompturi fileuri;
        rc = METADATA_DELOBJ(prompturi);
        rc = METADATA_DELOBJ(fileuri);
        put (_all_)(=);
      end;
      stop;
    end;

    /* create a TextStore object */
    rc11= METADATA_NEWOBJ('TextStore',texturi,'Stored Process');
    rc12= METADATA_SETATTR(texturi, 'TextRole','StoredProcessConfiguration');
    rc13= METADATA_SETATTR(texturi, 'TextType','XML');
    storedtext='<?xml version="1.0" encoding="UTF-8"?><StoredProcess>'
      !!"<ResultCapabilities Package='&package' Streaming='&streaming'/>"
      !!"<OutputParameters/></StoredProcess>";
    rc14= METADATA_SETATTR(texturi, 'StoredText',storedtext);
    if sum(of rc11-rc14) ne 0 then do;
      putlog "%str(WARN)ING: Issue creating TextStore.";
      if texturi ne . then do;
        putlog '  Removing orphans: ' prompturi fileuri texturi;
        rc = METADATA_DELOBJ(prompturi);
        rc = METADATA_DELOBJ(fileuri);
        rc = METADATA_DELOBJ(texturi);
        put (_all_)(=);
      end;
      stop;
    end;

    /* create meta obj */
    rc15= METADATA_NEWOBJ('ClassifierMap',stpuri,"&stpname");
    rc16= METADATA_SETASSN(stpuri, 'Trees','MODIFY',treeuri);
    rc17= METADATA_SETASSN(stpuri, 'ComputeLocations','MODIFY',serveruri);
    rc18= METADATA_SETASSN(stpuri, 'SourceCode','MODIFY',fileuri);
    rc19= METADATA_SETASSN(stpuri, 'Prompts','MODIFY',prompturi);
    rc20= METADATA_SETASSN(stpuri, 'Notes','MODIFY',texturi);
    rc21= METADATA_SETATTR(stpuri, 'PublicType', 'StoredProcess');
    rc22= METADATA_SETATTR(stpuri, 'TransformRole', 'StoredProcess');
    rc23= METADATA_SETATTR(stpuri, 'UsageVersion', '1000000');
    rc24= METADATA_SETATTR(stpuri, 'Desc', "&stpdesc");

    /* tidy up if err */
    if sum(of rc15-rc24) ne 0 then do;
      putlog "%str(WARN)ING: Issue creating STP.";
      if stpuri ne . then do;
        putlog '  Removing orphans: ' prompturi fileuri texturi stpuri;
        rc = METADATA_DELOBJ(prompturi);
        rc = METADATA_DELOBJ(fileuri);
        rc = METADATA_DELOBJ(texturi);
        rc = METADATA_DELOBJ(stpuri);
        put (_all_)(=);
      end;
    end;
    else do;
      fullpath=cats('_program=',treepath,"/&stpname");
      putlog "NOTE: Stored Process Created!";
      putlog "NOTE- "; putlog "NOTE-"; putlog "NOTE-" fullpath;
      putlog "NOTE- "; putlog "NOTE-";
    end;
    output;
    stop;
  run;
%end;
%else %if &stptype=2 %then %do;
  /* type 2 stp - code is stored in metadata */
  %if %sysevalf(&sysver lt 9.3) %then %do;
    %put %str(WARN)ING: SAS version 9.3 or later required to create type2 STPs;
    %return;
  %end;
  /* check we have the correct ServerContext */
  %mm_getservercontexts(outds=contexts)
  %local serveruri; %let serveruri=NOTFOUND;
  data _null_;
    set contexts;
    where upcase(servername)="%upcase(&server)";
    call symputx('serveruri',serveruri);
  run;
  %if &serveruri=NOTFOUND %then %do;
    %put %str(WARN)ING: ServerContext *&server* not found!;
    %return;
  %end;

  /**
    * First, create a Hello World type 2 stored process
    */
  filename &frefin temp;
  data _null_;
    file &frefin;
    treeuri=quote(symget('treeuri'));
    serveruri=quote(symget('serveruri'));
    stpdesc=quote(symget('stpdesc'));
    stpname=quote(symget('stpname'));

    put "<AddMetadata><Reposid>$METAREPOSITORY</Reposid><Metadata> "/
    '<ClassifierMap UsageVersion="2000000" IsHidden="0" IsUserDefined="0" '/
    ' IsActive="1" PublicType="StoredProcess" TransformRole="StoredProcess" '/
    '  Name=' stpname ' Desc=' stpdesc '>'/
    "  <ComputeLocations>"/
    "    <ServerContext ObjRef=" serveruri "/>"/
    "  </ComputeLocations>"/
    "<Notes> "/
    '  <TextStore IsHidden="0"  Name="SourceCode" UsageVersion="0" '/
    '    TextRole="StoredProcessSourceCode" StoredText="%put hello world!;" />'/
    '  <TextStore IsHidden="0" Name="Stored Process" UsageVersion="0" '/
    '    TextRole="StoredProcessConfiguration" TextType="XML" '/
    '    StoredText="&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&qu'@@
    'ot;?&gt;&lt;StoredProcess&gt;&lt;ServerContext LogicalServerType=&quot;S'@@
    'ps&quot; OtherAllowed=&quot;false&quot;/&gt;&lt;ResultCapabilities Packa'@@
    'ge=&quot;' @@ "&package" @@ '&quot; Streaming=&quot;' @@ "&streaming" @@
    '&quot;/&gt;&lt;OutputParameters/&gt;&lt;/StoredProcess&gt;" />' /
    "  </Notes> "/
    "  <Prompts> "/
    '   <PromptGroup  Name="Parameters" GroupType="2" IsHidden="0" '/
    '     PublicType="Embedded:PromptGroup" UsageVersion="1000000" '/
    '     GroupInfo="&lt;PromptGroup promptId=&quot;PromptGroup_1502797359253'@@
    '_802080&quot; version=&quot;1.0&quot;&gt;&lt;Label&gt;&lt;Text xml:lang='@@
    '&quot;en-US&quot;&gt;Parameters&lt;/Text&gt;&lt;/Label&gt;&lt;/PromptGro'@@
    'up&gt;" />'/
    "  </Prompts> "/
    "<Trees><Tree ObjRef=" treeuri "/></Trees>"/
    "</ClassifierMap></Metadata><NS>SAS</NS>"/
    "<Flags>268435456</Flags></AddMetadata>";
  run;

  filename &frefout temp;

  proc metadata in= &frefin out=&frefout ;
  run;

  %if &mdebug=1 %then %do;
    /* write the response to the log for debugging */
    data _null_;
      infile &frefout lrecl=1048576;
      input;
      put _infile_;
    run;
  %end;

  /**
    * Next, add the source code
    */
  %mm_updatestpsourcecode(stp=&tree/&stpname
    ,stpcode="&directory/&filename"
    ,mdebug=&mdebug
    ,minify=&minify)


%end;
%else %do;
  %put %str(WARN)ING:  STPTYPE=*&stptype* not recognised!;
%end;

%mend mm_createstp;/**
  @file mm_createwebservice.sas
  @brief Create a Web Ready Stored Process
  @details This macro creates a Type 2 Stored Process with the mm_webout macro
    included as pre-code.
Usage:

    %* compile macros ;
    filename mc url "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
    %inc mc;

    %* parmcards lets us write to a text file from open code ;
    filename ft15f001 temp;
    parmcards4;
        %* do some sas, any inputs are now already WORK tables;
        data example1 example2;
          set sashelp.class;
        run;
        %* send data back;
        %webout(OPEN)
        %webout(ARR,example1) * Array format, fast, suitable for large tables ;
        %webout(OBJ,example2) * Object format, easier to work with ;
        %webout(CLOSE)
    ;;;;
    %mm_createwebservice(path=/Public/app/common,name=appInit,code=ft15f001)

  <h4> SAS Macros </h4>
  @li mm_createstp.sas
  @li mf_getuser.sas
  @li mm_createfolder.sas
  @li mm_deletestp.sas

  @param path= The full path (in SAS Metadata) where the service will be created
  @param name= Stored Process name.  Avoid spaces - testing has shown that
    the check to avoid creating multiple STPs in the same folder with the same
    name does not work when the name contains spaces.
  @param desc= The description of the service (optional)
  @param precode= Space separated list of filerefs, pointing to the code that
    needs to be attached to the beginning of the service (optional)
  @param code=(ft15f001) Space seperated fileref(s) of the actual code to be
    added
  @param server=(SASApp) The server which will run the STP.  Server name or uri
    is fine.
  @param mDebug=(0) set to 1 to show debug messages in the log
  @param replace=(YES) select NO to avoid replacing an existing service in that
    location
  @param adapter=(sasjs) the macro uses the sasjs adapter by default.  To use
    another adapter, add a (different) fileref here.

  @version 9.2
  @author Allan Bowe

**/

%macro mm_createwebservice(path=
    ,name=initService
    ,precode=
    ,code=ft15f001
    ,desc=This stp was created automagically by the mm_createwebservice macro
    ,mDebug=0
    ,server=SASApp
    ,replace=YES
    ,adapter=sasjs
)/*/STORE SOURCE*/;

%if &syscc ge 4 %then %do;
  %put &=syscc - &sysmacroname will not execute in this state;
  %return;
%end;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing mm_createwebservice.sas;
%&mD.put _local_;

* remove any trailing slash ;
%if "%substr(&path,%length(&path),1)" = "/" %then
  %let path=%substr(&path,1,%length(&path)-1);

/**
  * Add webout macro
  * These put statements are auto generated - to change the macro, change the
  * source (mm_webout) and run `build.py`
  */
filename sasjs temp;
data _null_;
  file sasjs lrecl=3000 ;
  put "/* Created on %sysfunc(datetime(),datetime19.) by %mf_getuser() */";
/* WEBOUT BEGIN */
  put ' ';
  put '%macro mp_jsonout(action,ds,jref=_webout,dslabel=,fmt=Y,engine=DATASTEP,dbg=0 ';
  put ')/*/STORE SOURCE*/; ';
  put '%put output location=&jref; ';
  put '%if &action=OPEN %then %do; ';
  put '  options nobomfile; ';
  put '  data _null_;file &jref encoding=''utf-8'' ; ';
  put '    put ''{"PROCESSED_DTTM" : "'' "%sysfunc(datetime(),E8601DT26.6)" ''"''; ';
  put '  run; ';
  put '%end; ';
  put '%else %if (&action=ARR or &action=OBJ) %then %do; ';
  put '  options validvarname=upcase; ';
  put '  data _null_;file &jref mod encoding=''utf-8'' ; ';
  put '    put ", ""%lowcase(%sysfunc(coalescec(&dslabel,&ds)))"":"; ';
  put ' ';
  put '  %if &engine=PROCJSON %then %do; ';
  put '    data;run;%let tempds=&syslast; ';
  put '    proc sql;drop table &tempds; ';
  put '    data &tempds /view=&tempds;set &ds; ';
  put '    %if &fmt=N %then format _numeric_ best32.;; ';
  put '    proc json out=&jref pretty ';
  put '        %if &action=ARR %then nokeys ; ';
  put '        ;export &tempds / nosastags fmtnumeric; ';
  put '    run; ';
  put '    proc sql;drop view &tempds; ';
  put '  %end; ';
  put '  %else %if &engine=DATASTEP %then %do; ';
  put '    %local cols i tempds; ';
  put '    %let cols=0; ';
  put '    %if %sysfunc(exist(&ds)) ne 1 & %sysfunc(exist(&ds,VIEW)) ne 1 %then %do; ';
  put '      %put &sysmacroname:  &ds NOT FOUND!!!; ';
  put '      %return; ';
  put '    %end; ';
  put '    %if &fmt=Y %then %do; ';
  put '      %put converting every variable to a formatted variable; ';
  put '      /* see mp_ds2fmtds.sas for source */ ';
  put '      proc contents noprint data=&ds ';
  put '        out=_data_(keep=name type length format formatl formatd varnum); ';
  put '      run; ';
  put '      proc sort; ';
  put '        by varnum; ';
  put '      run; ';
  put '      %local fmtds; ';
  put '      %let fmtds=%scan(&syslast,2,.); ';
  put '      /* prepare formats and varnames */ ';
  put '      data _null_; ';
  put '        if _n_=1 then call symputx(''nobs'',nobs,''l''); ';
  put '        set &fmtds end=last nobs=nobs; ';
  put '        name=upcase(name); ';
  put '        /* fix formats */ ';
  put '        if type=2 or type=6 then do; ';
  put '          length fmt $49.; ';
  put '          if format='''' then fmt=cats(''$'',length,''.''); ';
  put '          else if formatl=0 then fmt=cats(format,''.''); ';
  put '          else fmt=cats(format,formatl,''.''); ';
  put '          newlen=max(formatl,length); ';
  put '        end; ';
  put '        else do; ';
  put '          if format='''' then fmt=''best.''; ';
  put '          else if formatl=0 then fmt=cats(format,''.''); ';
  put '          else if formatd=0 then fmt=cats(format,formatl,''.''); ';
  put '          else fmt=cats(format,formatl,''.'',formatd); ';
  put '          /* needs to be wide, for datetimes etc */ ';
  put '          newlen=max(length,formatl,24); ';
  put '        end; ';
  put '        /* 32 char unique name */ ';
  put '        newname=''sasjs''!!substr(cats(put(md5(name),$hex32.)),1,27); ';
  put ' ';
  put '        call symputx(cats(''name'',_n_),name,''l''); ';
  put '        call symputx(cats(''newname'',_n_),newname,''l''); ';
  put '        call symputx(cats(''len'',_n_),newlen,''l''); ';
  put '        call symputx(cats(''fmt'',_n_),fmt,''l''); ';
  put '        call symputx(cats(''type'',_n_),type,''l''); ';
  put '      run; ';
  put '      data &fmtds; ';
  put '        /* rename on entry */ ';
  put '        set &ds(rename=( ';
  put '      %local i; ';
  put '      %do i=1 %to &nobs; ';
  put '        &&name&i=&&newname&i ';
  put '      %end; ';
  put '        )); ';
  put '      %do i=1 %to &nobs; ';
  put '        length &&name&i $&&len&i; ';
  put '        &&name&i=left(put(&&newname&i,&&fmt&i)); ';
  put '        drop &&newname&i; ';
  put '      %end; ';
  put '        if _error_ then call symputx(''syscc'',1012); ';
  put '      run; ';
  put '      %let ds=&fmtds; ';
  put '    %end; /* &fmt=Y */ ';
  put '    data _null_;file &jref mod encoding=''utf-8'' ; ';
  put '      put "["; call symputx(''cols'',0,''l''); ';
  put '    proc sort ';
  put '      data=sashelp.vcolumn(where=(libname=''WORK'' & memname="%upcase(&ds)")) ';
  put '      out=_data_; ';
  put '      by varnum; ';
  put ' ';
  put '    data _null_; ';
  put '      set _last_ end=last; ';
  put '      call symputx(cats(''name'',_n_),name,''l''); ';
  put '      call symputx(cats(''type'',_n_),type,''l''); ';
  put '      call symputx(cats(''len'',_n_),length,''l''); ';
  put '      if last then call symputx(''cols'',_n_,''l''); ';
  put '    run; ';
  put ' ';
  put '    proc format; /* credit yabwon for special null removal */ ';
  put '      value bart ._ - .z = null ';
  put '      other = [best.]; ';
  put ' ';
  put '    data;run; %let tempds=&syslast; /* temp table for spesh char management */ ';
  put '    proc sql; drop table &tempds; ';
  put '    data &tempds/view=&tempds; ';
  put '      attrib _all_ label=''''; ';
  put '      %do i=1 %to &cols; ';
  put '        %if &&type&i=char %then %do; ';
  put '          length &&name&i $32767; ';
  put '          format &&name&i $32767.; ';
  put '        %end; ';
  put '      %end; ';
  put '      set &ds; ';
  put '      format _numeric_ bart.; ';
  put '    %do i=1 %to &cols; ';
  put '      %if &&type&i=char %then %do; ';
  put '        &&name&i=''"''!!trim(prxchange(''s/"/\"/'',-1, ';
  put '                    prxchange(''s/''!!''0A''x!!''/\n/'',-1, ';
  put '                    prxchange(''s/''!!''0D''x!!''/\r/'',-1, ';
  put '                    prxchange(''s/''!!''09''x!!''/\t/'',-1, ';
  put '                    prxchange(''s/\\/\\\\/'',-1,&&name&i) ';
  put '        )))))!!''"''; ';
  put '      %end; ';
  put '    %end; ';
  put '    run; ';
  put '    /* write to temp loc to avoid _webout truncation ';
  put '      - https://support.sas.com/kb/49/325.html */ ';
  put '    filename _sjs temp lrecl=131068 encoding=''utf-8''; ';
  put '    data _null_; file _sjs lrecl=131068 encoding=''utf-8'' mod ; ';
  put '      set &tempds; ';
  put '      if _n_>1 then put "," @; put ';
  put '      %if &action=ARR %then "[" ; %else "{" ; ';
  put '      %do i=1 %to &cols; ';
  put '        %if &i>1 %then  "," ; ';
  put '        %if &action=OBJ %then """&&name&i"":" ; ';
  put '        &&name&i ';
  put '      %end; ';
  put '      %if &action=ARR %then "]" ; %else "}" ; ; ';
  put '    proc sql; ';
  put '    drop view &tempds; ';
  put '    /* now write the long strings to _webout 1 byte at a time */ ';
  put '    data _null_; ';
  put '      length filein 8 fileid 8; ';
  put '      filein = fopen("_sjs",''I'',1,''B''); ';
  put '      fileid = fopen("&jref",''A'',1,''B''); ';
  put '      rec = ''20''x; ';
  put '      do while(fread(filein)=0); ';
  put '        rc = fget(filein,rec,1); ';
  put '        rc = fput(fileid, rec); ';
  put '        rc =fwrite(fileid); ';
  put '      end; ';
  put '      rc = fclose(filein); ';
  put '      rc = fclose(fileid); ';
  put '    run; ';
  put '    filename _sjs clear; ';
  put '    data _null_; file &jref mod encoding=''utf-8'' ; ';
  put '      put "]"; ';
  put '    run; ';
  put '  %end; ';
  put '%end; ';
  put ' ';
  put '%else %if &action=CLOSE %then %do; ';
  put '  data _null_;file &jref encoding=''utf-8'' mod ; ';
  put '    put "}"; ';
  put '  run; ';
  put '%end; ';
  put '%mend mp_jsonout; ';
  put '%macro mm_webout(action,ds,dslabel=,fref=_webout,fmt=Y); ';
  put '%global _webin_file_count _webin_fileref1 _webin_name1 _program _debug ';
  put '  sasjs_tables; ';
  put '%local i tempds jsonengine; ';
  put ' ';
  put '/* see https://github.com/sasjs/core/issues/41 */ ';
  put '%if "%upcase(&SYSENCODING)" ne "UTF-8" %then %let jsonengine=PROCJSON; ';
  put '%else %let jsonengine=DATASTEP; ';
  put ' ';
  put ' ';
  put '%if &action=FETCH %then %do; ';
  put '  %if %str(&_debug) ge 131 %then %do; ';
  put '    options mprint notes mprintnest; ';
  put '  %end; ';
  put '  %let _webin_file_count=%eval(&_webin_file_count+0); ';
  put '  /* now read in the data */ ';
  put '  %do i=1 %to &_webin_file_count; ';
  put '    %if &_webin_file_count=1 %then %do; ';
  put '      %let _webin_fileref1=&_webin_fileref; ';
  put '      %let _webin_name1=&_webin_name; ';
  put '    %end; ';
  put '    data _null_; ';
  put '      infile &&_webin_fileref&i termstr=crlf; ';
  put '      input; ';
  put '      call symputx(''input_statement'',_infile_); ';
  put '      putlog "&&_webin_name&i input statement: "  _infile_; ';
  put '      stop; ';
  put '    data &&_webin_name&i; ';
  put '      infile &&_webin_fileref&i firstobs=2 dsd termstr=crlf encoding=''utf-8''; ';
  put '      input &input_statement; ';
  put '      %if %str(&_debug) ge 131 %then %do; ';
  put '        if _n_<20 then putlog _infile_; ';
  put '      %end; ';
  put '    run; ';
  put '    %let sasjs_tables=&sasjs_tables &&_webin_name&i; ';
  put '  %end; ';
  put '%end; ';
  put ' ';
  put '%else %if &action=OPEN %then %do; ';
  put '  /* fix encoding */ ';
  put '  OPTIONS NOBOMFILE; ';
  put ' ';
  put '  /** ';
  put '    * check xengine type to avoid the below err message: ';
  put '    * > Function is only valid for filerefs using the CACHE access method. ';
  put '    */ ';
  put '  data _null_; ';
  put '    set sashelp.vextfl(where=(fileref="_WEBOUT")); ';
  put '    if xengine=''STREAM'' then do; ';
  put '      rc=stpsrv_header(''Content-type'',"text/html; encoding=utf-8"); ';
  put '    end; ';
  put '  run; ';
  put ' ';
  put '  /* setup json */ ';
  put '  data _null_;file &fref encoding=''utf-8''; ';
  put '  %if %str(&_debug) ge 131 %then %do; ';
  put '    put ''>>weboutBEGIN<<''; ';
  put '  %end; ';
  put '    put ''{"START_DTTM" : "'' "%sysfunc(datetime(),datetime20.3)" ''"''; ';
  put '  run; ';
  put ' ';
  put '%end; ';
  put ' ';
  put '%else %if &action=ARR or &action=OBJ %then %do; ';
  put '  %mp_jsonout(&action,&ds,dslabel=&dslabel,fmt=&fmt,jref=&fref ';
  put '    ,engine=&jsonengine,dbg=%str(&_debug) ';
  put '  ) ';
  put '%end; ';
  put '%else %if &action=CLOSE %then %do; ';
  put '  %if %str(&_debug) ge 131 %then %do; ';
  put '    /* if debug mode, send back first 10 records of each work table also */ ';
  put '    options obs=10; ';
  put '    data;run;%let tempds=%scan(&syslast,2,.); ';
  put '    ods output Members=&tempds; ';
  put '    proc datasets library=WORK memtype=data; ';
  put '    %local wtcnt;%let wtcnt=0; ';
  put '    data _null_; ';
  put '      set &tempds; ';
  put '      if not (upcase(name) =:"DATA"); /* ignore temp datasets */ ';
  put '      i+1; ';
  put '      call symputx(''wt''!!left(i),name,''l''); ';
  put '      call symputx(''wtcnt'',i,''l''); ';
  put '    data _null_; file &fref mod encoding=''utf-8''; ';
  put '      put ",""WORK"":{"; ';
  put '    %do i=1 %to &wtcnt; ';
  put '      %let wt=&&wt&i; ';
  put '      proc contents noprint data=&wt ';
  put '        out=_data_ (keep=name type length format:); ';
  put '      run;%let tempds=%scan(&syslast,2,.); ';
  put '      data _null_; file &fref mod encoding=''utf-8''; ';
  put '        dsid=open("WORK.&wt",''is''); ';
  put '        nlobs=attrn(dsid,''NLOBS''); ';
  put '        nvars=attrn(dsid,''NVARS''); ';
  put '        rc=close(dsid); ';
  put '        if &i>1 then put '',''@; ';
  put '        put " ""&wt"" : {"; ';
  put '        put ''"nlobs":'' nlobs; ';
  put '        put '',"nvars":'' nvars; ';
  put '      %mp_jsonout(OBJ,&tempds,jref=&fref,dslabel=colattrs,engine=&jsonengine) ';
  put '      %mp_jsonout(OBJ,&wt,jref=&fref,dslabel=first10rows,engine=&jsonengine) ';
  put '      data _null_; file &fref mod encoding=''utf-8''; ';
  put '        put "}"; ';
  put '    %end; ';
  put '    data _null_; file &fref mod encoding=''utf-8''; ';
  put '      put "}"; ';
  put '    run; ';
  put '  %end; ';
  put '  /* close off json */ ';
  put '  data _null_;file &fref mod encoding=''utf-8''; ';
  put '    _PROGRAM=quote(trim(resolve(symget(''_PROGRAM'')))); ';
  put '    put ",""SYSUSERID"" : ""&sysuserid"" "; ';
  put '    put ",""MF_GETUSER"" : ""%mf_getuser()"" "; ';
  put '    put ",""_DEBUG"" : ""&_debug"" "; ';
  put '    _METAUSER=quote(trim(symget(''_METAUSER''))); ';
  put '    put ",""_METAUSER"": " _METAUSER; ';
  put '    _METAPERSON=quote(trim(symget(''_METAPERSON''))); ';
  put '    put '',"_METAPERSON": '' _METAPERSON; ';
  put '    put '',"_PROGRAM" : '' _PROGRAM ; ';
  put '    put ",""SYSCC"" : ""&syscc"" "; ';
  put '    put ",""SYSERRORTEXT"" : ""&syserrortext"" "; ';
  put '    put ",""SYSHOSTNAME"" : ""&syshostname"" "; ';
  put '    put ",""SYSJOBID"" : ""&sysjobid"" "; ';
  put '    put ",""SYSSCPL"" : ""&sysscpl"" "; ';
  put '    put ",""SYSSITE"" : ""&syssite"" "; ';
  put '    sysvlong=quote(trim(symget(''sysvlong''))); ';
  put '    put '',"SYSVLONG" : '' sysvlong; ';
  put '    put ",""SYSWARNINGTEXT"" : ""&syswarningtext"" "; ';
  put '    put '',"END_DTTM" : "'' "%sysfunc(datetime(),datetime20.3)" ''" ''; ';
  put '    put "}" @; ';
  put '  %if %str(&_debug) ge 131 %then %do; ';
  put '    put ''>>weboutEND<<''; ';
  put '  %end; ';
  put '  run; ';
  put '%end; ';
  put ' ';
  put '%mend mm_webout; ';
  put ' ';
  put '%macro mf_getuser(type=META ';
  put ')/*/STORE SOURCE*/; ';
  put '  %local user metavar; ';
  put '  %if &type=OS %then %let metavar=_secureusername; ';
  put '  %else %let metavar=_metaperson; ';
  put ' ';
  put '  %if %symexist(SYS_COMPUTE_SESSION_OWNER) %then %let user=&SYS_COMPUTE_SESSION_OWNER; ';
  put '  %else %if %symexist(&metavar) %then %do; ';
  put '    %if %length(&&&metavar)=0 %then %let user=&sysuserid; ';
  put '    /* sometimes SAS will add @domain extension - remove for consistency */ ';
  put '    %else %let user=%scan(&&&metavar,1,@); ';
  put '  %end; ';
  put '  %else %let user=&sysuserid; ';
  put ' ';
  put '  %quote(&user) ';
  put ' ';
  put '%mend mf_getuser; ';
/* WEBOUT END */
  put '%macro webout(action,ds,dslabel=,fmt=);';
  put '  %mm_webout(&action,ds=&ds,dslabel=&dslabel,fmt=&fmt)';
  put '%mend;';
run;

/* add precode and code */
%local work tmpfile;
%let work=%sysfunc(pathname(work));
%let tmpfile=__mm_createwebservice.temp;
%local x fref freflist mod;
%let freflist= &adapter &precode &code ;
%do x=1 %to %sysfunc(countw(&freflist));
  %if &x>1 %then %let mod=mod;

  %let fref=%scan(&freflist,&x);
  %put &sysmacroname: adding &fref;
  data _null_;
    file "&work/&tmpfile" lrecl=3000 &mod;
    infile &fref;
    input;
    put _infile_;
  run;
%end;

/* create the metadata folder if not already there */
%mm_createfolder(path=&path)
%if &syscc ge 4 %then %return;

%if %upcase(&replace)=YES %then %do;
  %mm_deletestp(target=&path/&name)
%end;

/* create the web service */
%mm_createstp(stpname=&name
  ,filename=&tmpfile
  ,directory=&work
  ,tree=&path
  ,stpdesc=&desc
  ,mDebug=&mdebug
  ,server=&server
  ,stptype=2)

/* find the web app url */
%local url;
%let url=localhost/SASStoredProcess;
data _null_;
  length url $128;
  rc=METADATA_GETURI("Stored Process Web App",url);
  if rc=0 then call symputx('url',url,'l');
run;

%put ;%put ;%put ;%put ;%put ;%put ;
%put &sysmacroname: STP &name successfully created in &path;
%put ;%put ;%put ;
%put Check it out here:;
%put ;%put ;%put ;
%put &url?_PROGRAM=&path/&name;
%put ;%put ;%put ;%put ;%put ;%put ;

%mend mm_createwebservice;
/**
  @file mm_deletedocument.sas
  @brief Deletes a Document using path as reference
  @details

  Usage:

    %mm_createdocument(tree=/User Folders/&sysuserid,name=MyNote)
    %mm_deletedocument(target=/User Folders/&sysuserid/MyNote)

  <h4> SAS Macros </h4>

  @param target= full path to the document being deleted

  @version 9.4
  @author Allan Bowe

**/

%macro mm_deletedocument(
    target=
)/*/STORE SOURCE*/;

/**
  * Check document exist
  */
%local type;
data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&target",'Note',type,uri);
  call symputx('type',type,'l');
  call symputx('stpuri',uri,'l');
run;
%if &type ne Document %then %do;
  %put %str(WARN)ING: No Document found at &target;
  %return;
%end;

filename __in temp lrecl=10000;
filename __out temp lrecl=10000;
data _null_ ;
  file __in ;
  put "<DeleteMetadata><Metadata><Document Id='&stpuri'/>";
  put "</Metadata><NS>SAS</NS><Flags>268436480</Flags><Options/>";
  put "</DeleteMetadata>";
run ;
proc metadata in=__in out=__out verbose;run;

/* list the result */
data _null_;infile __out; input; list; run;

filename __in clear;
filename __out clear;

/**
  * Check deletion
  */
%local isgone;
data _null_;
  length type uri $256;
  call missing (of _all_);
  rc=metadata_pathobj("","&target",'Note',type,uri);
  call symputx('isgone',type,'l');
run;
%if &isgone = Document %then %do;
  %put %str(ERR)OR: Document not deleted from &target;
  %let syscc=4;
  %return;
%end;

%mend mm_deletedocument;
/**
  @file
  @brief Deletes a library by Name

  @details  Used to delete a library.
  Usage:

      %* create a library in the home directory ;
      %mm_createlibrary(
        libname=My Temp Library,
        libref=XXTEMPXX,
        tree=/User Folders/&sysuserid,
        directory=%sysfunc(pathname(work))
      )

      %* delete the library ;
      %mm_deletelibrary(name=My Temp Library)

  After running the above, the following will be shown in the log:

  ![](https://i.imgur.com/Y4Tog24.png)

  @param [in] name= the name (not libref) of the library to be deleted

  <h4> SAS Macros </h4>
  @li mf_getuniquefileref.sas
  @li mp_abort.sas


  @version 9.4
  @author Allan Bowe

**/

%macro mm_deletelibrary(
      name=
)/*/STORE SOURCE*/;


/**
  * Check if library exists and get uri
  */
data _null_;
  length type uri $256;
  rc=metadata_resolve("omsobj:SASLibrary?@Name='&name'",type,uri);
  call symputx('checktype',type,'l');
  call symputx('liburi',uri,'l');
  putlog (_all_)(=);
run;
%if &checktype ne SASLibrary %then %do;
  %put &sysmacroname: Library (&name) was not found, and so will not be deleted;
  %return;
%end;

%local fname1 fname2;
%let fname1=%mf_getuniquefileref();
%let fname2=%mf_getuniquefileref();

filename &fname1 temp lrecl=10000;
filename &fname2 temp lrecl=10000;
data _null_ ;
  file &fname1 ;
  put "<DeleteMetadata><Metadata><SASLibrary Id='&liburi'/>";
  put "</Metadata><NS>SAS</NS><Flags>268436480</Flags><Options/>";
  put "</DeleteMetadata>";
run ;
proc metadata in=&fname1 out=&fname2 verbose;run;

/* list the result */
data _null_;infile &fname2; input; list; run;

filename &fname1 clear;
filename &fname2 clear;

/**
  * Check deletion
  */
%local isgone;
data _null_;
  length type uri $256;
  rc=metadata_resolve("omsobj:SASLibrary?@Id='&liburi'",type,uri);
  call symputx('isgone',type,'l');
run;

%mp_abort(iftrue=(&isgone = SASLibrary)
  ,mac=&sysmacroname
  ,msg=%str(Library (&name) NOT deleted)
)

%put &sysmacroname: Library &name (&liburi) was successfully deleted;

%mend mm_deletelibrary;
/**
  @file mm_deletestp.sas
  @brief Deletes a Stored Process using path as reference
  @details Will only delete the metadata, not any physical files associated.

  Usage:

    %mm_deletestp(target=/some/meta/path/myStoredProcess)

  <h4> SAS Macros </h4>

  @param target= full path to the STP being deleted

  @version 9.4
  @author Allan Bowe

**/

%macro mm_deletestp(
    target=
)/*/STORE SOURCE*/;

/**
  * Check STP does exist
  */
%local cmtype;
data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&target",'StoredProcess',type,uri);
  call symputx('cmtype',type,'l');
  call symputx('stpuri',uri,'l');
run;
%if &cmtype ne ClassifierMap %then %do;
  %put NOTE: No Stored Process found at &target;
  %return;
%end;

filename __in temp lrecl=10000;
filename __out temp lrecl=10000;
data _null_ ;
  file __in ;
  put "<DeleteMetadata><Metadata><ClassifierMap Id='&stpuri'/>";
  put "</Metadata><NS>SAS</NS><Flags>268436480</Flags><Options/>";
  put "</DeleteMetadata>";
run ;
proc metadata in=__in out=__out verbose;run;

/* list the result */
data _null_;infile __out; input; list; run;

filename __in clear;
filename __out clear;

/**
  * Check deletion
  */
%local isgone;
data _null_;
  length type uri $256;
  call missing (of _all_);
  rc=metadata_pathobj("","&target",'Note',type,uri);
  call symputx('isgone',type,'l');
run;
%if &isgone = ClassifierMap %then %do;
  %put %str(ERR)OR: STP not deleted from &target;
  %let syscc=4;
  %return;
%end;

%mend mm_deletestp;
/**
  @file mm_getauthinfo.sas
  @brief extracts authentication info
  @details usage:

    %mm_getauthinfo(outds=auths)

  @param outds= the ONE LEVEL work dataset to create

  <h4> SAS Macros </h4>
  @li mm_getobjects.sas
  @li mf_getuniquefileref.sas
  @li mm_getdetails.sas

  @version 9.4
  @author Allan Bowe

**/

%macro mm_getauthinfo(outds=mm_getauthinfo
)/*/STORE SOURCE*/;

%if %length(&outds)>30 %then %do;
  %put %str(ERR)OR: Temp tables are created with the &outds prefix, which
    therefore needs to be 30 characters or less;
  %return;
%end;
%if %index(&outds,'.')>0 %then %do;
  %put %str(ERR)OR: Table &outds should be ONE LEVEL (no library);
  %return;
%end;

%mm_getobjects(type=Login,outds=&outds.0)

%local fileref;
%let fileref=%mf_getuniquefileref();

data _null_;
  file &fileref;
  set &outds.0 end=last;
  /* run macro */
  str=cats('%mm_getdetails(uri=',id,",outattrs=&outds.d",_n_
    ,",outassocs=&outds.a",_n_,")");
  put str;
  /* transpose attributes */
  str=cats("proc transpose data=&outds.d",_n_,"(drop=type) out=&outds.da"
    ,_n_,"(drop=_name_);var value;id name;run;");
  put str;
  /* add extra info to attributes */
  str=cats("data &outds.da",_n_,";length login_id login_name $256; login_id="
    ,quote(trim(id)),";set &outds.da",_n_
    ,";login_name=trim(subpad(name,1,256));drop name;run;");
  put str;
  /* add extra info to associations */
  str=cats("data &outds.a",_n_,";length login_id login_name $256; login_id="
    ,quote(trim(id)),";login_name=",quote(trim(name))
    ,";set &outds.a",_n_,";run;");
  put str;
  if last then do;
    /* collate attributes */
    str=cats("data &outds._logat; set &outds.da1-&outds.da",_n_,";run;");
    put str;
    /* collate associations */
    str=cats("data &outds._logas; set &outds.a1-&outds.a",_n_,";run;");
    put str;
    /* tidy up */
    str=cats("proc delete data=&outds.da1-&outds.da",_n_,";run;");
    put str;
    str=cats("proc delete data=&outds.d1-&outds.d",_n_,";run;");
    put str;
    str=cats("proc delete data=&outds.a1-&outds.a",_n_,";run;");
    put str;
  end;
run;
%inc &fileref;

/* get libraries */
proc sort data=&outds._logas(where=(assoc='Libraries')) out=&outds._temp;
  by login_id;
data &outds._temp;
  set &outds._temp;
  by login_id;
  length library_list $32767;
  retain library_list;
  if first.login_id then library_list=name;
  else library_list=catx(' !! ',library_list,name);
proc sql;
/* get auth domain */
create table &outds._dom as
  select login_id,name as domain
  from &outds._logas
  where assoc='Domain';
create unique index login_id on &outds._dom(login_id);
/* join it all together */
create table &outds._logins as
  select a.*
    ,c.domain
    ,b.library_list
  from &outds._logat (drop=ishidden lockedby usageversion publictype) a
  left join &outds._temp b
  on a.login_id=b.login_id
  left join &outds._dom c
  on a.login_id=c.login_id;
drop table &outds._temp;
drop table &outds._logat;
drop table &outds._logas;

data _null_;
  infile &fileref;
  if _n_=1 then putlog // "Now executing the following code:" //;
  input; putlog _infile_;
run;

filename &fileref clear;

%mend mm_getauthinfo;/**
  @file
  @brief Creates a dataset with all metadata columns for a particular table
  @details

  usage:

    %mm_getcols(tableuri=A5X8AHW1.B40001S5)

  @param outds the dataset to create that contains the list of columns
  @param uri the uri of the table for which to return columns

  @returns outds  dataset containing all columns, specifically:
    - colname
    - coluri
    - coldesc

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getcols(
    tableuri=
    ,outds=work.mm_getcols
)/*/STORE SOURCE*/;

data &outds;
  keep col: SAS:;
  length assoc uri coluri colname coldesc SASColumnType SASFormat SASInformat
      SASPrecision SASColumnLength $256;
  call missing (of _all_);
  uri=symget('tableuri');
  n=1;
  do while (metadata_getnasn(uri,'Columns',n,coluri)>0);
    rc3=metadata_getattr(coluri,"Name",colname);
    rc3=metadata_getattr(coluri,"Desc",coldesc);
    rc4=metadata_getattr(coluri,"SASColumnType",SASColumnType);
    rc5=metadata_getattr(coluri,"SASFormat",SASFormat);
    rc6=metadata_getattr(coluri,"SASInformat",SASInformat);
    rc7=metadata_getattr(coluri,"SASPrecision",SASPrecision);
    rc8=metadata_getattr(coluri,"SASColumnLength",SASColumnLength);
    output;
    call missing(colname,coldesc,SASColumnType,SASFormat,SASInformat
      ,SASPrecision,SASColumnLength);
    n+1;
  end;
run;
proc sort;
  by colname;
run;

%mend mm_getcols;/**
  @file mm_getdetails.sas
  @brief extracts metadata attributes and associations for a particular uri

  @param uri the metadata object for which to return attributes / associations
  @param outattrs= the dataset to create that contains the list of attributes
  @param outassocs= the dataset to contain the list of associations

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getdetails(uri
  ,outattrs=work.attributes
  ,outassocs=work.associations
)/*/STORE SOURCE*/;

data &outassocs;
  keep assoc assocuri name;
  length assoc assocuri name $256;
  call missing(of _all_);
  rc1=1;n1=1;
  do while(rc1>0);
    /* Walk through all possible associations of this object. */
    rc1=metadata_getnasl("&uri",n1,assoc);
    rc2=1;n2=1;
    do while(rc2>0);
      /* Walk through all the associations on this machine object. */
      rc2=metadata_getnasn("&uri",trim(assoc),n2,assocuri);
      if (rc2>0) then do;
        rc3=metadata_getattr(assocuri,"Name",name);
        output;
      end;
      call missing(name,assocuri);
      n2+1;
    end;
    n1+1;
  end;
run;
proc sort;
  by assoc name;
run;

data &outattrs;
  keep type name value;
  length type $4 name $256 value $32767;
  rc1=1;n1=1;type='Prop';name='';value='';
  do while(rc1>0);
    rc1=metadata_getnprp("&uri",n1,name,value);
    if rc1>0 then output;
    n1+1;
  end;
  rc1=1;n1=1;type='Attr';
  do while(rc1>0);
    rc1=metadata_getnatr("&uri",n1,name,value);
    if rc1>0 then output;
    n1+1;
  end;
run;
proc sort;
  by type name;
run;

%mend mm_getdetails;/**
  @file
  @brief Returns a dataset with the meta directory object for a physical path
  @details Provide a file path to get matching directory objects, or leave
    blank to return all directories.  The Directory object is used to reference
    a physical filepath (eg when registering a .sas program in a Stored process)

  @param path= the physical path for which to return a meta Directory object
  @param outds= the dataset to create that contains the list of directories
  @param mDebug= set to 1 to show debug messages in the log

  @returns outds  dataset containing the following columns:
    - directoryuri
    - groupname
    - groupdesc

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getDirectories(
    path=
    ,outds=work.mm_getDirectories
    ,mDebug=0
)/*/STORE SOURCE*/;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing mm_getDirectories.sas;
%&mD.put _local_;

data &outds (keep=directoryuri name directoryname directorydesc );
  length directoryuri name directoryname directorydesc $256;
  call missing(of _all_);
  __i+1;
%if %length(&path)=0 %then %do;
  do while
  (metadata_getnobj("omsobj:Directory?@Id contains '.'",__i,directoryuri)>0);
%end; %else %do;
  do while(
    metadata_getnobj("omsobj:Directory?@DirectoryName='&path'",__i,directoryuri)
    >0
  );
%end;
    __rc1=metadata_getattr(directoryuri, "Name", name);
    __rc2=metadata_getattr(directoryuri, "DirectoryName", directoryname);
    __rc3=metadata_getattr(directoryuri, "Desc", directorydesc);
    &mD.putlog (_all_) (=);
    drop __:;
    __i+1;
    if sum(of __rc1-__rc3)=0 then output;
  end;
run;

%mend mm_getDirectories;
/**
  @file
  @brief Writes the TextStore of a Document Object to an external file
  @details If the document exists, and has a textstore object, the contents
    of that textstore are written to an external file.

  usage:

      %mm_getdocument(tree=/some/meta/path
        ,name=someDocument
        ,outref=/some/unquoted/filename.ext
      )

  <h4> SAS Macros </h4>
  @li mp_abort.sas

  @param tree= The metadata path of the document
  @param name= Document object name.
  @param outref= full and unquoted path to the desired text file.  This will be
    overwritten if it already exists.

  @author Allan Bowe

**/

%macro mm_getdocument(
    tree=/User Folders/sasdemo
    ,name=myNote
    ,outref=%sysfunc(pathname(work))/mm_getdocument.txt
    ,mDebug=1
    );

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing &sysmacroname..sas;
%&mD.put _local_;

/**
  * check tree exists
  */

data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&tree","Folder",type,uri);
  call symputx('type',type,'l');
  call symputx('treeuri',uri,'l');
run;

%mp_abort(
  iftrue= (&type ne Tree)
  ,mac=mm_getdocument.sas
  ,msg=Tree &tree does not exist!
)

/**
  * Check object exists
  */
data _null_;
  length type docuri tsuri tsid $256 ;
  rc1=metadata_pathobj("","&tree/&name","Note",type,docuri);
  rc2=metadata_getnasn(docuri,"Notes",1,tsuri);
  rc3=metadata_getattr(tsuri,"Id",tsid);
  call symputx('type',type,'l');
  call symputx("tsid",tsid,'l');
  putlog (_all_)(=);
run;

%mp_abort(
  iftrue= (&type ne Document)
  ,mac=mm_getdocument.sas
  ,msg=Document &name could not be found in &tree!
)

/**
  * Now we can extract the textstore
  */
filename __getdoc temp lrecl=10000000;
proc metadata
  in="<GetMetadata><Reposid>$METAREPOSITORY</Reposid>
      <Metadata><TextStore Id='&tsid'/></Metadata>
      <Ns>SAS</Ns><Flags>1</Flags><Options/></GetMetadata>"
  out=__getdoc ;
run;

/* find the beginning of the text */
data _null_;
  infile __getdoc lrecl=10000;
  input;
  start=index(_infile_,'StoredText="');
  if start then do;
    call symputx("start",start+11);
    put start= "type=&type";
    putlog '"' _infile_ '"';
  end;
  stop;

/* read the content, byte by byte, resolving escaped chars */
filename __outdoc "&outref" lrecl=100000;
data _null_;
  length filein 8 fileid 8;
  filein = fopen("__getdoc","I",1,"B");
  fileid = fopen("__outdoc","O",1,"B");
  rec = "20"x;
  length entity $6;
  do while(fread(filein)=0);
    x+1;
    if x>&start then do;
      rc = fget(filein,rec,1);
      if rec='"' then leave;
      else if rec="&" then do;
        entity=rec;
        do until (rec=";");
          if fread(filein) ne 0 then goto getout;
          rc = fget(filein,rec,1);
          entity=cats(entity,rec);
        end;
        select (entity);
          when ('&amp;' ) rec='&'  ;
          when ('&lt;'  ) rec='<'  ;
          when ('&gt;'  ) rec='>'  ;
          when ('&apos;') rec="'"  ;
          when ('&quot;') rec='"'  ;
          when ('&#x0a;') rec='0A'x;
          when ('&#x0d;') rec='0D'x;
          when ('&#36;' ) rec='$'  ;
          when ('&#x09;') rec='09'x;
          otherwise putlog "%str(WARN)ING: missing value for " entity=;
        end;
        rc =fput(fileid, substr(rec,1,1));
        rc =fwrite(fileid);
      end;
      else do;
        rc =fput(fileid,rec);
        rc =fwrite(fileid);
      end;
    end;
  end;
  getout:
  rc=fclose(filein);
  rc=fclose(fileid);
run;
filename __getdoc clear;
filename __outdoc clear;

%mend mm_getdocument;
/**
  @file
  @brief Returns all direct child members of a particular folder
  @details Displays the children for a particular folder, in a similar fashion
  to the viya counterpart (mv_getfoldermembers.sas)

  Usage:

      %mm_getfoldermembers(root=/, outds=rootfolders)

      %mm_getfoldermembers(root=/User Folders/&sysuserid, outds=usercontent)

  @param [in] root= the parent folder under which to return all contents
  @param [out] outds= the dataset to create that contains the list of
    directories
  @param [in] mDebug= set to 1 to show debug messages in the log

  <h4> Data Outputs </h4>

  Example for `root=/`:

  |metauri $17|metaname $256|metatype $32|
  |---|---|---|
  |A5XLSNXI.AA000001|Products  |Folder|
  |A5XLSNXI.AA000002|Shared Data  |Folder|
  |A5XLSNXI.AA000003|User Folders  |Folder|
  |A5XLSNXI.AA000004|System  |Folder|
  |A5XLSNXI.AA00003K|30.SASApps  |Folder|
  |A5XLSNXI.AA00006A|Public|Folder|

  <h4> SAS Macros </h4>
  @li mm_getfoldertree.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas

  @version 9.4
  @author Allan Bowe

**/
%macro mm_getfoldermembers(
    root=
    ,outds=work.mm_getfoldertree
)/*/STORE SOURCE*/;

%if "&root" = "/" %then %do;
  %local fname1 fname2 fname3;
  %let fname1=%mf_getuniquefileref();
  %let fname2=%mf_getuniquefileref();
  %let fname3=%mf_getuniquefileref();
  data _null_ ;
    file &fname1 ;
    put '<GetMetadataObjects>' ;
    put '<Reposid>$METAREPOSITORY</Reposid>' ;
    put '<Type>Tree</Type>' ;
    put '<NS>SAS</NS>' ;
    put '<Flags>388</Flags>' ;
    put '<Options>' ;
    put '<XMLSelect search="Tree[SoftwareComponents/SoftwareComponent'@;
    put '[@Name=''BIP Service'']]"/>';
    put '</Options>' ;
    put '</GetMetadataObjects>' ;
  run ;
  proc metadata in=&fname1 out=&fname2 verbose;run;

  /* create an XML map to read the response */
  data _null_;
    file &fname3;
    put '<SXLEMAP version="1.2" name="SASFolders">';
    put '<TABLE name="SASFolders">';
    put '<TABLE-PATH syntax="XPath">//Objects/Tree</TABLE-PATH>';
    put '<COLUMN name="metauri">><LENGTH>17</LENGTH>';
    put '<PATH syntax="XPath">//Objects/Tree/@Id</PATH></COLUMN>';
    put '<COLUMN name="metaname"><LENGTH>256</LENGTH>>';
    put '<PATH syntax="XPath">//Objects/Tree/@Name</PATH></COLUMN>';
    put '</TABLE></SXLEMAP>';
  run;
  %local libref1;
  %let libref1=%mf_getuniquelibref();
  libname &libref1 xml xmlfileref=&fname2 xmlmap=&fname3;

  data &outds;
    length metatype $32;
    retain metatype 'Folder';
    set &libref1..sasfolders;
  run;

%end;
%else %do;
  %mm_getfoldertree(root=&root, outds=&outds,depth=1)
  data &outds;
    set &outds(rename=(name=metaname publictype=metatype));
    keep metaname metauri metatype;
  run;
%end;

%mend mm_getfoldermembers;
/**
  @file
  @brief Returns all folders / subfolder content for a particular root
  @details Shows all members and SubTrees recursively for a particular root.
  Note - for big sites, this returns a lot of data!  So you may wish to reduce
  the logging to speed up the process (see example below), OR - use mm_tree.sas
  which uses proc metadata and is far more efficient.

  Usage:

    options ps=max nonotes nosource;
    %mm_getfoldertree(root=/My/Meta/Path, outds=iwantthisdataset)
    options notes source;

  @param [in] root= the parent folder under which to return all contents
  @param [out] outds= the dataset to create that contains the list of
    directories
  @param [in] mDebug= set to 1 to show debug messages in the log

  <h4> SAS Macros </h4>

  @version 9.4
  @author Allan Bowe

**/
%macro mm_getfoldertree(
    root=
    ,outds=work.mm_getfoldertree
    ,mDebug=0
    ,depth=50 /* how many nested folders to query */
    ,level=1 /* system var - to track current level depth */
    ,append=NO  /* system var - when YES means appending within nested loop */
)/*/STORE SOURCE*/;

%if &level>&depth %then %return;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing &sysmacroname;
%&mD.put _local_;

%if &append=NO %then %do;
  /* ensure table doesn't exist already */
  data &outds; run;
  proc sql; drop table &outds;
%end;

/* get folder contents */
data &outds.TMP/view=&outds.TMP;
  length metauri pathuri $64 name $256 path $1024
    assoctype publictype MetadataUpdated MetadataCreated $32;
  keep metauri assoctype name publictype MetadataUpdated MetadataCreated path;
  call missing(of _all_);
  path="&root";
  rc=metadata_pathobj("",path,"Folder",publictype,pathuri);
  if publictype ne 'Tree' then do;
    putlog "%str(WAR)NING: Tree " path 'does not exist!' publictype=;
    stop;
  end;
  __n1=1;
  do while(metadata_getnasl(pathuri,__n1,assoctype)>0);
    __n1+1;
    /* Walk through all possible associations of this object. */
    __n2=1;
    if assoctype in ('Members','SubTrees') then
    do while(metadata_getnasn(pathuri,assoctype,__n2,metauri)>0);
      __n2+1;
      call missing(name,publictype,MetadataUpdated,MetadataCreated);
      __rc1=metadata_getattr(metauri,"Name", name);
      __rc2=metadata_getattr(metauri,"MetadataUpdated", MetadataUpdated);
      __rc3=metadata_getattr(metauri,"MetadataCreated", MetadataCreated);
      __rc4=metadata_getattr(metauri,"PublicType", PublicType);
      output;
    end;
    n1+1;
  end;
  drop __:;
run;

proc append base=&outds data=&outds.TMP;
run;

data _null_;
  set &outds.TMP(where=(assoctype='SubTrees'));
  call execute('%mm_getfoldertree(root='
    !!cats(path,"/",name)!!",outds=&outds,mDebug=&mdebug,depth=&depth"
    !!",level=%eval(&level+1),append=YES)");
run;

%mend mm_getfoldertree;
/**
  @file
  @brief Creates dataset with all members of a metadata group
  @details

  usage:

    %mm_getgroupmembers(someGroupName
      ,outds=work.mm_getgroupmembers
      ,emails=YES)

  @param group metadata group for which to bring back members
  @param outds= the dataset to create that contains the list of members
  @param emails= set to YES to bring back email addresses
  @param id= set to yes if passing an ID rather than a group name

  @returns outds  dataset containing all members of the metadata group

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getgroupmembers(
    group /* metadata group for which to bring back members */
    ,outds=work.mm_getgroupmembers /* output dataset to contain the results */
    ,emails=NO /* set to yes to bring back emails also */
    ,id=NO /* set to yes if passing an ID rather than group name */
)/*/STORE SOURCE*/;

  data &outds ;
    attrib uriGrp uriMem GroupId GroupName Group_or_Role MemberName MemberType
      euri email           length=$64
      GroupDesc            length=$256
      rcGrp rcMem rc i j   length=3;
    call missing (of _all_);
    drop uriGrp uriMem rcGrp rcMem rc i j arc ;

    i=1;
    * Grab the URI for the first Group ;
    %if &id=NO %then %do;
      rcGrp=metadata_getnobj("omsobj:IdentityGroup?@Name='&group'",i,uriGrp);
    %end;
    %else %do;
      rcGrp=metadata_getnobj("omsobj:IdentityGroup?@Id='&group'",i,uriGrp);
    %end;
    * If Group found, enter do loop ;
    if rcGrp>0 then do;
      call missing (rcMem,uriMem,GroupId,GroupName,Group_or_Role
        ,MemberName,MemberType);
      * get group info ;
      rc = metadata_getattr(uriGrp,"Id",GroupId);
      rc = metadata_getattr(uriGrp,"Name",GroupName);
      rc = metadata_getattr(uriGrp,"PublicType",Group_or_Role);
      rc = metadata_getattr(uriGrp,"Desc",GroupDesc);
      j=1;
      do while (metadata_getnasn(uriGrp,"MemberIdentities",j,uriMem) > 0);
        call missing (MemberName, MemberType, email);
        rc = metadata_getattr(uriMem,"Name",MemberName);
        rc = metadata_getattr(uriMem,"PublicType",MemberType);
        if membertype='User' and "&emails"='YES' then do;
          if metadata_getnasn(uriMem,"EmailAddresses",1,euri)>0 then do;
            arc=metadata_getattr(euri,"Address",email);
          end;
        end;
        output;
        j+1;
      end;
    end;
  run;

%mend mm_getgroupmembers;
/**
  @file
  @brief Creates dataset with all groups or just those for a particular user
  @details Provide a metadata user to get groups for just that user, or leave
    blank to return all groups.
  Usage:

    - all groups: `%mm_getGroups()`

    - all groups for a particular user: `%mm_getgroups(user=&sysuserid)`

  @param [in] user= the metadata user to return groups for.  Leave blank for all
    groups.
  @param [in] repo= the metadata repository that contains the user/group
    information
  @param [in] mDebug= set to 1 to show debug messages in the log
  @param [out] outds= the dataset to create that contains the list of groups

  @returns outds  dataset containing all groups in a column named "metagroup"
    - groupuri
    - groupname
    - groupdesc

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getGroups(
    user=
    ,outds=work.mm_getGroups
    ,repo=foundation
    ,mDebug=0
)/*/STORE SOURCE*/;

%local mD oldrepo;
%let oldrepo=%sysfunc(getoption(metarepository));
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing mm_getGroups.sas;
%&mD.put _local_;

/* on some sites, user / group info is in a different metadata repo to the
    default */
%if &oldrepo ne &repo %then %do;
  options metarepository=&repo;
%end;

%if %length(&user)=0 %then %do;
  data &outds (keep=groupuri groupname groupdesc);
    length groupuri groupname groupdesc group_or_role $256;
    call missing(of _all_);
    i+1;
    do while
    (metadata_getnobj("omsobj:IdentityGroup?@Id contains '.'",i,groupuri)>0);
      rc=metadata_getattr(groupuri, "Name", groupname);
      rc=metadata_getattr(groupuri, "Desc", groupdesc);
      rc=metadata_getattr(groupuri,"PublicType",group_or_role);
      if Group_or_Role = 'UserGroup' then output;
      i+1;
    end;
  run;
%end;
%else %do;
  data &outds (keep=groupuri groupname groupdesc);
    length uri groupuri groupname groupdesc group_or_role $256;
    call missing(of _all_);
    rc=metadata_getnobj("omsobj:Person?@Name='&user'",1,uri);
    if rc<=0 then do;
      putlog "%str(WARN)ING: rc=" rc "&user not found "
          ", or there was an issue reading the repository.";
      stop;
    end;
    a=1;
    grpassn=metadata_getnasn(uri,"IdentityGroups",a,groupuri);
    if grpassn in (-3,-4) then do;
      putlog "%str(WARN)ING: No metadata groups found for &user";
      output;
    end;
    else do while (grpassn > 0);
      rc=metadata_getattr(groupuri, "Name", groupname);
      rc=metadata_getattr(groupuri, "Desc", groupdesc);
      a+1;
      rc=metadata_getattr(groupuri,"PublicType",group_or_role);
      if Group_or_Role = 'UserGroup' then output;
      grpassn=metadata_getnasn(uri,"IdentityGroups",a,groupuri);
    end;
  run;
%end;

%if &oldrepo ne &repo %then %do;
  options metarepository=&oldrepo;
%end;

%mend mm_getGroups;/**
  @file
  @brief Compares the metadata of a library with the physical tables
  @details Creates a series of output tables that show the differences between
  metadata and physical tables.
  Each output can be created with an optional prefix.

  Credit - Paul Homes
  https://platformadmin.com/blogs/paul/2012/11/sas-proc-metalib-ods-output

  Usage:

      %* create (and assign) a library for testing purposes ;
      %mm_createlibrary(
        libname=My Temp Library,
        libref=XXTEMPXX,
        tree=/User Folders/&sysuserid,
        directory=%sysfunc(pathname(work))
      )

      %* create some tables;
      data work.table1 table2 table3;
        a=1;b='two';c=3;
      run;

      %* register the tables;
      proc metalib;
        omr=(library="My Temp Library");
        report(type=detail);
        update_rule (delete);
      run;

      %* modify the tables;
      proc sql;
      drop table table3;
      alter table table2 drop c;
      alter table table2 add d num;

      %* run the macro;
      %mm_getlibmetadiffs(libname=My Temp Library)

      %* delete the library ;
      %mm_deletelibrary(name=My Temp Library)

  The program will create four output tables, with the following structure (and
  example data):

  #### &prefix.added
  |name:$32.|metaID:$17.|SAStabName:$32.|
  |---|---|---|
  | | |DATA1|

  #### &prefix.deleted
  |name:$32.|metaID:$17.|SAStabName:$32.|
  |---|---|---|
  |TABLE3|A5XLSNXI.BK0001HO|TABLE3|

  #### &prefix.updated
  |tabName:$32.|tabMetaID:$17.|SAStabName:$32.|metaName:$32.|metaID:$17.|sasname:$32.|metaType:$16.|change:$64.|
  |---|---|---|---|---|---|---|---|
  |TABLE2|A5XLSNXI.BK0001HN|TABLE2|c|A5XLSNXI.BM000MA9|c|Column|Deleted|
  | | | |d| |d|Column|Added|

  #### &prefix.meta
  |Label1:$28.|cValue1:$1.|nValue1:D12.3|
  |---|---|---|
  |Total tables analyzed|4|4|
  |Tables to be Updated|1|1|
  |Tables to be Deleted|1|1|
  |Tables to be Added|1|1|
  |Tables matching data source|1|1|
  |Tables not processed|0|0|

  If you are interested in more functionality like this (checking the health of
  SAS metadata and your SAS 9 environment) then do contact [Allan Bowe](
  https://www.linkedin.com/in/allanbowe) for details of our SAS 9 Health Check
  service.

  Our system scan will perform hundreds of checks to identify common issues,
  such as dangling metadata, embedded passwords, security issues and more.

  @param [in] libname= the metadata name of the library to be compared
  @param [out] outlib=(work) The library in which to store the output tables.
  @param [out] prefix=(metadiff) The prefix for the four tables created.

  @version 9.3
  @author Allan Bowe

**/

%macro mm_getlibmetadiffs(
  libname= ,
  prefix=metadiff,
  outlib=work
)/*/STORE SOURCE*/;

  /* create tempds */
  data;run;
  %local tempds;
  %let tempds=&syslast;

  /* save options */
  proc optsave out=&tempds;
  run;

  options VALIDVARNAME=ANY VALIDMEMNAME=EXTEND;

  ods output
    factoid1=&outlib..&prefix.meta
    updtab=&outlib..&prefix.updated
    addtab=&outlib..&prefix.added
    deltab=&outlib..&prefix.deleted
  ;

  proc metalib;
    omr=(library="&libname");
    noexec;
    report(type=detail);
    update_rule (delete);
  run;

  ods output close;

  /* restore options */
  proc optload data=&tempds;
  run;

%mend mm_getlibmetadiffs;
/**
  @file
  @brief Creates a dataset with all metadata libraries
  @details Will only show the libraries to which a user has the requisite
    metadata access.

  @param outds the dataset to create that contains the list of libraries
  @param mDebug set to anything but * or 0 to show debug messages in the log

  @returns outds  dataset containing all groups in a column named "metagroup"
    (defaults to work.mm_getlibs). The following columns are provided:
    - LibraryId
    - LibraryName
    - LibraryRef
    - Engine

  @warning The following filenames are created and then de-assigned:

      filename sxlemap clear;
      filename response clear;
      libname _XML_ clear;

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getlibs(
    outds=work.mm_getLibs
)/*/STORE SOURCE*/;

/*
  flags:

  OMI_SUCCINCT     (2048) Do not return attributes with null values.
  OMI_GET_METADATA (256)  Executes a GetMetadata call for each object that
                          is returned by the GetMetadataObjects method.
  OMI_ALL_SIMPLE   (8)    Gets all of the attributes of the requested object.
*/
data _null_;
  flags=2048+256+8;
  call symputx('flags',flags,'l');
run;

* use a temporary fileref to hold the response;
filename response temp;
/* get list of libraries */
proc metadata in=
  '<GetMetadataObjects>
  <Reposid>$METAREPOSITORY</Reposid>
  <Type>SASLibrary</Type>
  <Objects/>
  <NS>SAS</NS>
  <Flags>&flags</Flags>
  <Options/>
  </GetMetadataObjects>'
  out=response;
run;

/* write the response to the log for debugging */
data _null_;
  infile response lrecl=32767;
  input;
  put _infile_;
run;

/* create an XML map to read the response */
filename sxlemap temp;
data _null_;
  file sxlemap;
  put '<SXLEMAP version="1.2" name="SASLibrary">';
  put '<TABLE name="SASLibrary">';
  put '<TABLE-PATH syntax="XPath">//Objects/SASLibrary</TABLE-PATH>';
  put '<COLUMN name="LibraryId">><LENGTH>17</LENGTH>';
  put '<PATH syntax="XPath">//Objects/SASLibrary/@Id</PATH></COLUMN>';
  put '<COLUMN name="LibraryName"><LENGTH>256</LENGTH>>';
  put '<PATH syntax="XPath">//Objects/SASLibrary/@Name</PATH></COLUMN>';
  put '<COLUMN name="LibraryRef"><LENGTH>8</LENGTH>';
  put '<PATH syntax="XPath">//Objects/SASLibrary/@Libref</PATH></COLUMN>';
  put '<COLUMN name="Engine">><LENGTH>12</LENGTH>';
  put '<PATH syntax="XPath">//Objects/SASLibrary/@Engine</PATH></COLUMN>';
  put '</TABLE></SXLEMAP>';
run;
libname _XML_ xml xmlfileref=response xmlmap=sxlemap;

/* sort the response by library name */
proc sort data=_XML_.saslibrary out=&outds;
  by libraryname;
run;


/* clear references */
filename sxlemap clear;
filename response clear;
libname _XML_ clear;

%mend mm_getlibs;/**
  @file
  @brief Creates a dataset with all metadata objects for a particular type

  @param type= the metadata type for which to return all objects
  @param outds= the dataset to create that contains the list of types

  @returns outds  dataset containing all objects

  @warning The following filenames are created and then de-assigned:

      filename sxlemap clear;
      filename response clear;
      libname _XML_ clear;

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getobjects(
  type=SASLibrary
  ,outds=work.mm_getobjects
)/*/STORE SOURCE*/;


* use a temporary fileref to hold the response;
filename response temp;
/* get list of libraries */
proc metadata in=
  "<GetMetadataObjects><Reposid>$METAREPOSITORY</Reposid>
    <Type>&type</Type><Objects/><NS>SAS</NS>
    <Flags>0</Flags><Options/></GetMetadataObjects>"
    out=response;
run;

/* write the response to the log for debugging */
data _null_;
  infile response lrecl=1048576;
  input;
  put _infile_;
run;

/* create an XML map to read the response */
filename sxlemap temp;
data _null_;
  file sxlemap;
  put '<SXLEMAP version="1.2" name="SASObjects"><TABLE name="SASObjects">';
  put "<TABLE-PATH syntax='XPath'>/GetMetadataObjects/Objects/&type";
  put "</TABLE-PATH>";
  put '<COLUMN name="id">';
  put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/&type/@Id</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>200</LENGTH>";
  put '</COLUMN><COLUMN name="name">';
  put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/&type/@Name</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>200</LENGTH>";
  put '</COLUMN></TABLE></SXLEMAP>';
run;
libname _XML_ xml xmlfileref=response xmlmap=sxlemap;

proc sort data= _XML_.SASObjects out=&outds;
  by name;
run;

/* clear references */
filename sxlemap clear;
filename response clear;
libname _XML_ clear;

%mend mm_getobjects;/**
  @file mm_getpublictypes.sas
  @brief Creates a dataset with all deployable public types
  @details More info:
  https://support.sas.com/documentation/cdl/en/bisag/65422/HTML/default/viewer.htm#n1nkrdzsq5iunln18bk2236istkb.htm

  Usage:

        * dataset will contain one column - publictype ($64);
        %mm_getpublictypes(outds=types)

  @returns outds= dataset containing all types

  @version 9.3
  @author Allan Bowe

**/

%macro mm_getpublictypes(
    outds=work.mm_getpublictypes
)/*/STORE SOURCE*/;

proc sql;
create table &outds (publictype char(64)); /* longest is currently 52 */
insert into &outds values ('ACT');
insert into &outds values ('Action');
insert into &outds values ('Application');
insert into &outds values ('ApplicationServer');
insert into &outds values ('BurstDefinition');
insert into &outds values ('Channel');
insert into &outds values ('Condition');
insert into &outds values ('ConditionActionSet');
insert into &outds values ('ContentSubscriber');
insert into &outds values ('Cube');
insert into &outds values ('DataExploration');
insert into &outds values ('DeployedFlow');
insert into &outds values ('DeployedJob');
insert into &outds values ('Document');
insert into &outds values ('EventSubscriber');
insert into &outds values ('ExternalFile');
insert into &outds values ('FavoritesFolder');
insert into &outds values ('Folder');
insert into &outds values ('Folder.SecuredData');
insert into &outds values ('GeneratedTransform');
insert into &outds values ('InformationMap');
insert into &outds values ('InformationMap.OLAP');
insert into &outds values ('InformationMap.Relational');
insert into &outds values ('JMSDestination (Java Messaging System message queue)');
insert into &outds values ('Job');
insert into &outds values ('Job.Cube');
insert into &outds values ('Library');
insert into &outds values ('MessageQueue');
insert into &outds values ('MiningResults');
insert into &outds values ('MQM.JMS (queue manager for Java Messaging Service)');
insert into &outds values ('MQM.MSMQ (queue manager for MSMQ)');
insert into &outds values ('MQM.Websphere (queue manager for WebSphere MQ)');
insert into &outds values ('Note');
insert into &outds values ('OLAPSchema');
insert into &outds values ('Project');
insert into &outds values ('Project.EG');
insert into &outds values ('Project.AMOExcel');
insert into &outds values ('Project.AMOPowerPoint');
insert into &outds values ('Project.AMOWord');
insert into &outds values ('Prompt');
insert into &outds values ('PromptGroup');
insert into &outds values ('Report');
insert into &outds values ('Report.Component');
insert into &outds values ('Report.Image');
insert into &outds values ('Report.StoredProcess');
insert into &outds values ('Role');
insert into &outds values ('SearchFolder');
insert into &outds values ('SecuredLibrary');
insert into &outds values ('Server');
insert into &outds values ('Service.SoapGenerated');
insert into &outds values ('SharedDimension');
insert into &outds values ('Spawner.Connect');
insert into &outds values ('Spawner.IOM (object spawner)');
insert into &outds values ('StoredProcess');
insert into &outds values ('SubscriberGroup.Content');
insert into &outds values ('SubscriberGroup.Event');
insert into &outds values ('Table');
insert into &outds values ('User');
insert into &outds values ('UserGroup');
quit;

%mend mm_getpublictypes;/**
  @file
  @brief Creates a dataset with all available repositories

  @param outds= the dataset to create that contains the list of repos

  @returns outds  dataset containing all repositories

  @warning The following filenames are created and then de-assigned:

      filename sxlemap clear;
      filename response clear;
      libname _XML_ clear;

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getrepos(
  outds=work.mm_getrepos
)/*/STORE SOURCE*/;


* use a temporary fileref to hold the response;
filename response temp;
/* get list of libraries */
proc metadata in=
  "<GetRepositories><Repositories/><Flags>1</Flags><Options/></GetRepositories>"
    out=response;
run;

/* write the response to the log for debugging */
/*
data _null_;
  infile response lrecl=1048576;
  input;
  put _infile_;
run;
*/

/* create an XML map to read the response */
filename sxlemap temp;
data _null_;
  file sxlemap;
  put '<SXLEMAP version="1.2" name="SASRepos"><TABLE name="SASRepos">';
  put "<TABLE-PATH syntax='XPath'>/GetRepositories/Repositories/Repository";
  put "</TABLE-PATH>";
  put '<COLUMN name="id">';
  put "<PATH syntax='XPath'>/GetRepositories/Repositories/Repository/@Id";
  put "</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>200</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="name">';
  put "<PATH syntax='XPath'>/GetRepositories/Repositories/Repository/@Name";
  put "</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>200</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="desc">';
  put "<PATH syntax='XPath'>/GetRepositories/Repositories/Repository/@Desc";
  put "</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>200</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="DefaultNS">';
  put "<PATH syntax='XPath'>";
  put "/GetRepositories/Repositories/Repository/@DefaultNS</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>200</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="RepositoryType">';
  put "<PATH syntax='XPath'>";
  put "/GetRepositories/Repositories/Repository/@RepositoryType</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>20</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="RepositoryFormat">';
  put "<PATH syntax='XPath'>";
  put "/GetRepositories/Repositories/Repository/@RepositoryFormat</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>10</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="Access">';
  put "<PATH syntax='XPath'>";
  put "/GetRepositories/Repositories/Repository/@Access</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>16</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="CurrentAccess">';
  put "<PATH syntax='XPath'>";
  put "/GetRepositories/Repositories/Repository/@CurrentAccess</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>16</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="PauseState">';
  put "<PATH syntax='XPath'>";
  put "/GetRepositories/Repositories/Repository/@PauseState</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>16</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="Path">';
  put "<PATH syntax='XPath'>/GetRepositories/Repositories/Repository/@Path";
  put "</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>256</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="Engine">';
  put "<PATH syntax='XPath'>/GetRepositories/Repositories/Repository/@Engine";
  put "</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>8</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="Options">';
  put "<PATH syntax='XPath'>/GetRepositories/Repositories/Repository/@Options";
  put "</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>32</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="MetadataCreated">';
  put "<PATH syntax='XPath'>";
  put "/GetRepositories/Repositories/Repository/@MetadataCreated</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>24</LENGTH>";
  put '</COLUMN>';
  put '<COLUMN name="MetadataUpdated">';
  put "<PATH syntax='XPath'>";
  put "/GetRepositories/Repositories/Repository/@MetadataUpdated</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>24</LENGTH>";
  put '</COLUMN>';
  put '</TABLE></SXLEMAP>';
run;
libname _XML_ xml xmlfileref=response xmlmap=sxlemap;

proc sort data= _XML_.SASRepos out=&outds;
  by name;
run;

/* clear references */
filename sxlemap clear;
filename response clear;
libname _XML_ clear;

%mend mm_getrepos;/**
  @file mm_getroles.sas
  @brief Creates a table containing a list of roles
  @details

  Usage:

      %mm_getroles()

  @param [out] outds the dataset to create that contains the list of roles

  @returns outds  dataset containing all roles, with the following columns:
    - uri
    - name

  @warning The following filenames are created and then de-assigned:

      filename sxlemap clear;
      filename response clear;
      libname _XML_ clear;

  @version 9.3
  @author Allan Bowe

**/

%macro mm_getroles(
    outds=work.mm_getroles
)/*/STORE SOURCE*/;

filename response temp;
options noquotelenmax;
proc metadata in= '<GetMetadataObjects><Reposid>$METAREPOSITORY</Reposid>
  <Type>IdentityGroup</Type><NS>SAS</NS><Flags>388</Flags>
  <Options>
  <Templates><IdentityGroup Name="" Desc="" PublicType=""/></Templates>
  <XMLSelect search="@PublicType=''Role''"/>
  </Options>
  </GetMetadataObjects>'
    out=response;
run;

filename sxlemap temp;
data _null_;
  file sxlemap;
  put '<SXLEMAP version="1.2" name="roles"><TABLE name="roles">';
  put "<TABLE-PATH syntax='XPath'>/GetMetadataObjects/Objects/IdentityGroup";
  put "</TABLE-PATH>";
  put '<COLUMN name="roleuri">';
  put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/IdentityGroup/@Id";
  put "</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>32</LENGTH>";
  put '</COLUMN><COLUMN name="rolename">';
  put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/IdentityGroup/@Name";
  put "</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>256</LENGTH>";
  put '</COLUMN><COLUMN name="roledesc">';
  put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/IdentityGroup/@Desc";
  put "</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>500</LENGTH>";
  put '</COLUMN></TABLE></SXLEMAP>';
run;
libname _XML_ xml xmlfileref=response xmlmap=sxlemap;

proc sort data= _XML_.roles out=&outds;
  by rolename;
run;

filename sxlemap clear;
filename response clear;
libname _XML_ clear;

%mend mm_getroles;
/**
  @file mm_getservercontexts.sas
  @brief Creates a dataset with all server contexts in all repos
  @details
  Usage:

    %mm_getservercontexts(outds=mm_getservercontexts)

  @param outds= the dataset to create that contains the list

  @warning The following filenames are created and then de-assigned:

      filename __mc1 clear;
      filename __mc2 clear;
      libname __mc3 clear;

  <h4> SAS Macros </h4>
  @li mm_getrepos.sas

  @version 9.3
  @author Allan Bowe

**/

%macro mm_getservercontexts(
  outds=work.mm_getrepos
)/*/STORE SOURCE*/;
%local repo repocnt x;
%let repo=%sysfunc(getoption(metarepository));

/* first get list of available repos */
%mm_getrepos(outds=work.repos)
%let repocnt=0;
data _null_;
  set repos;
  where repositorytype in('CUSTOM','FOUNDATION');
  keep id name ;
  call symputx('repo'!!left(_n_),name,'l');
  call symputx('repocnt',_n_,'l');
run;

filename __mc1 temp;
filename __mc2 temp;
data &outds; length serveruri servername $200; stop;run;
%do x=1 %to &repocnt;
  options metarepository=&&repo&x;
  proc metadata in=
  "<GetMetadataObjects><Reposid>$METAREPOSITORY</Reposid>
  <Type>ServerContext</Type><Objects/><NS>SAS</NS>
  <Flags>0</Flags><Options/></GetMetadataObjects>"
    out=__mc1;
  run;
  /*
  data _null_;
    infile __mc1 lrecl=1048576;
    input;
    put _infile_;
  run;
  */
  data _null_;
    file __mc2;
    put '<SXLEMAP version="1.2" name="SASContexts"><TABLE name="SASContexts">';
    put "<TABLE-PATH syntax='XPath'>/GetMetadataObjects/Objects/ServerContext</TABLE-PATH>";
    put '<COLUMN name="serveruri">';
    put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/ServerContext/@Id</PATH>";
    put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>200</LENGTH>";
    put '</COLUMN>';
    put '<COLUMN name="servername">';
    put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/ServerContext/@Name</PATH>";
    put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>200</LENGTH>";
    put '</COLUMN>';
    put '</TABLE></SXLEMAP>';
  run;
  libname __mc3 xml xmlfileref=__mc1 xmlmap=__mc2;
  proc append base=&outds data=__mc3.SASContexts;run;
  libname __mc3 clear;
%end;

options metarepository=&repo;

filename __mc1 clear;
filename __mc2 clear;

%mend mm_getservercontexts;/**
  @file
  @brief Writes the code of an STP to an external file
  @details Fetches the SAS code from a Stored Process where the code is stored
  in metadata.

  Usage:

      %mm_getstpcode(tree=/some/meta/path
        ,name=someSTP
        ,outloc=/some/unquoted/filename.ext
      )

  @param [in] tree= The metadata path of the Stored Process (can also contain
    name)
  @param [in] name= Stored Process name.  Leave blank if included above.
  @param [out] outloc= (0) full and unquoted path to the desired text file.
    This will be overwritten if it already exists.
  @param [out] outref= (0) Fileref to which to write the code.
  @param [out] showlog=(NO) Set to YES to print log to the window

  <h4> SAS Macros </h4>
  @li mf_getuniquefileref.sas

  @author Allan Bowe

**/

%macro mm_getstpcode(
    tree=/User Folders/sasdemo/somestp
    ,name=
    ,outloc=0
    ,outref=0
    ,mDebug=1
    ,showlog=NO
    );

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing &sysmacroname..sas;
%&mD.put _local_;

%if %length(&name)>0 %then %let name=/&name;

/* first, check if STP exists */
%local tsuri;
%let tsuri=stopifempty ;

data _null_;
  format type uri tsuri value $200.;
  call missing (of _all_);
  path="&tree&name(StoredProcess)";
  /* first, find the STP ID */
  if metadata_pathobj("",path,"StoredProcess",type,uri)>0 then do;
    /* get sourcecode */
    cnt=1;
    do while (metadata_getnasn(uri,"Notes",cnt,tsuri)>0);
      rc=metadata_getattr(tsuri,"Name",value);
      put tsuri= value=;
      if value="SourceCode" then do;
        /* found it! */
        rc=metadata_getattr(tsuri,"Id",value);
        call symputx('tsuri',value,'l');
        stop;
      end;
      cnt+1;
    end;
  end;
  else put (_all_)(=);
run;

%if &tsuri=stopifempty %then %do;
  %put %str(WARN)ING:  &tree&name.(StoredProcess) not found!;
  %return;
%end;


/**
  * Now we can extract the textstore
  */
filename __getdoc temp lrecl=10000000;
proc metadata
  in="<GetMetadata><Reposid>$METAREPOSITORY</Reposid>
      <Metadata><TextStore Id='&tsuri'/></Metadata>
      <Ns>SAS</Ns><Flags>1</Flags><Options/></GetMetadata>"
  out=__getdoc ;
run;

/* find the beginning of the text */
%local start;
data _null_;
  infile __getdoc lrecl=10000;
  input;
  start=index(_infile_,'StoredText="');
  if start then do;
    call symputx("start",start+11);
    *putlog '"' _infile_ '"';
  end;
  stop;

%local outeng;
%if "&outloc"="0" %then %let outeng=TEMP;
%else %let outeng="&outloc";
%local fref;
%if &outref=0 %then %let fref=%mf_getuniquefileref();
%else %let fref=&outref;

/* read the content, byte by byte, resolving escaped chars */
filename &fref &outeng lrecl=100000;
data _null_;
  length filein 8 fileid 8;
  filein = fopen("__getdoc","I",1,"B");
  fileid = fopen("&fref","O",1,"B");
  rec = "20"x;
  length entity $6;
  do while(fread(filein)=0);
    x+1;
    if x>&start then do;
      rc = fget(filein,rec,1);
      if rec='"' then leave;
      else if rec="&" then do;
        entity=rec;
        do until (rec=";");
          if fread(filein) ne 0 then goto getout;
          rc = fget(filein,rec,1);
          entity=cats(entity,rec);
        end;
        select (entity);
          when ('&amp;' ) rec='&'  ;
          when ('&lt;'  ) rec='<'  ;
          when ('&gt;'  ) rec='>'  ;
          when ('&apos;') rec="'"  ;
          when ('&quot;') rec='"'  ;
          when ('&#x0a;') rec='0A'x;
          when ('&#x0d;') rec='0D'x;
          when ('&#36;' ) rec='$'  ;
          when ('&#x09;') rec='09'x;
          otherwise putlog "%str(WARN)ING: missing value for " entity=;
        end;
        rc =fput(fileid, substr(rec,1,1));
        rc =fwrite(fileid);
      end;
      else do;
        rc =fput(fileid,rec);
        rc =fwrite(fileid);
      end;
    end;
  end;
  getout:
  rc=fclose(filein);
  rc=fclose(fileid);
run;

%if &showlog=YES %then %do;
  data _null_;
    infile &fref lrecl=32767 end=last;
    input;
    if _n_=1 then putlog '>>stpcodeBEGIN<<';
    putlog _infile_;
    if last then putlog '>>stpcodeEND<<';
  run;
%end;

filename __getdoc clear;
%if &outref=0 %then %do;
  filename &fref clear;
%end;

%mend mm_getstpcode;
/**
  @file
  @brief Returns a dataset with all Stored Processes, or just those in a
    particular folder / with a  particular name.
  @details Leave blank to get all stps.  Provide a Tree (path or uri) or a
    name (not case sensitive) to filter that way also.
  usage:

      %mm_getstps()

      %mm_getstps(name=My STP)

      %mm_getstps(tree=/My Folder/My STPs)

      %mm_getstps(tree=/My Folder/My STPs, name=My STP)

  <h4> SAS Macros </h4>
  @li mm_gettree.sas

  @param tree= the metadata folder location in which to search.  Leave blank
    for all folders.  Does not search subdirectories.
  @param name= Provide the name of an STP to search for just that one.  Can
    combine with the <code>tree=</code> parameter.
  @param outds= the dataset to create that contains the list of stps.
  @param mDebug= set to 1 to show debug messages in the log
  @param showDesc= provide a non blank value to return stored process
    descriptions
  @param showUsageVersion= provide a non blank value to return the UsageVersion.
    This is either 1000000 (type 1, 9.2) or 2000000 (type2, 9.3 onwards).

  @returns outds  dataset containing the following columns
    - stpuri
    - stpname
    - treeuri
    - stpdesc (if requested)
    - usageversion (if requested)

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getstps(
    tree=
    ,name=
    ,outds=work.mm_getstps
    ,mDebug=0
    ,showDesc=
    ,showUsageVersion=
)/*/STORE SOURCE*/;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing mm_getstps.sas;
%&mD.put _local_;

data &outds;
  length stpuri stpname usageversion treeuri stpdesc $256;
  call missing (of _all_);
run;

%if %length(&tree)>0 %then %do;
  /* get tree info */
  %mm_gettree(tree=&tree,inds=&outds, outds=&outds, mDebug=&mDebug)
  %if %mf_nobs(&outds)=0 %then %do;
    %put NOTE:  Tree &tree did not exist!!;
    %return;
  %end;
%end;


data &outds ;
  set &outds(rename=(treeuri=treeuri_compare));
  length treeuri query stpuri $256;
  i+1;
%if %length(&name)>0 %then %do;
  query="omsobj:ClassifierMap?@PublicType='StoredProcess' and @Name='&name'";
  putlog query=;
%end;
%else %do;
  query="omsobj:ClassifierMap?@PublicType='StoredProcess'";
%end;
%if &mDebug=1 %then %do;
  putlog 'start' (_all_)(=);
%end;
  do while(0<metadata_getnobj(query,i,stpuri));
    i+1;
    rc1=metadata_getattr(stpuri,"Name", stpname);
    rc2=metadata_getnasn(stpuri,"Trees",1,treeuri);
  %if %length(&tree)>0 %then %do;
    if treeuri ne treeuri_compare then goto exitloop;
  %end;
  %if %length(&showDesc)>0 %then %do;
    rc3=metadata_getattr(stpuri,"Desc", stpdesc);
    keep stpdesc;
  %end;
  %if %length(&showUsageVersion)>0 %then %do;
    rc4=metadata_getattr(stpuri,"UsageVersion",UsageVersion);
    keep usageversion;
  %end;
    output;
    &mD.put (_all_)(=);
    exitloop:
  end;
  keep stpuri stpname treeuri;
run;

%mend mm_getstps;
/**
  @file mm_gettableid.sas
  @brief Get the metadata id for a particular table
  @details Provide a libref and table name to return the corresponding metadata
  in an output datataset.

  Usage:

      - get a table id
      %mm_gettableid(libref=METALIB,ds=SOMETABLE,outds=iwant)

  @param libref= The libref to search
  @param ds= The input dataset to check
  @param outds= the dataset to create that contains the `tableuri`
  @param mDebug= set to 1 to show debug messages in the log

  @returns outds  dataset containing `tableuri` and `tablename`

  @version 9.3
  @author Allan Bowe

**/

%macro mm_gettableid(
    libref=
    ,ds=
    ,outds=work.mm_gettableid
    ,mDebug=0
)/*/STORE SOURCE*/;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing &sysmacroname..sas;
%&mD.put _local_;

data &outds;
  length uri usingpkguri id type tableuri tablename tmpuri $256;
  call missing(of _all_);
  keep tableuri tablename;
  n=1;
  rc=0;
  if metadata_getnobj("omsobj:SASLibrary?@Libref='&libref'",n,uri)<1 then do;
    put "Library &libref not found";
    stop;
  end;
  &mD.putlog "uri is " uri;
  if metadata_getnasn(uri, "UsingPackages", 1, usingpkguri)>0 then do;
    rc=metadata_resolve(usingpkguri,type,id);
    &mD.putlog "Type is " type;
  end;

  if type='DatabaseSchema' then tmpuri=usingpkguri;
  else tmpuri=uri;

  t=1;
  do while(metadata_getnasn(tmpuri, "Tables", t, tableuri)>0);
    t+1;
    rc= metadata_getattr(tableuri, "Name", tablename);
    &mD.putlog "Table is " tablename;
    if upcase(tablename)="%upcase(&ds)" then do;
      output;
    end;
  end;
run;

%mend mm_gettableid;/**
  @file
  @brief Creates a dataset with all metadata tables for a particular library
  @details Will only show the tables for which the executing user has the
    requisite metadata access.

  usage:

      %mm_gettables(uri=A5X8AHW1.B40001S5)

  @param [in] uri= the uri of the library for which to return tables
  @param [out] outds= (work.mm_gettables) the dataset to contain the list of
    tables
  @param [in] getauth= (YES) Fetch the authdomain used in database connections.
    Set to NO to improve runtimes in larger environments, as there can be a
    performance hit on the `metadata_getattr(domainuri, "Name", AuthDomain)`
    call.

  @returns outds  dataset containing all groups in a column named "metagroup"
    (defaults to work.mm_getlibs). The following columns are provided:
    - tablename
    - tableuri
    - libref
    - libname
    - libdesc

  @version 9.2
  @author Allan Bowe

**/

%macro mm_gettables(
    uri=
    ,outds=work.mm_gettables
    ,getauth=YES
)/*/STORE SOURCE*/;


data &outds;
  length uri serveruri conn_uri domainuri libname ServerContext AuthDomain
    path_schema usingpkguri type tableuri $256 id $17
    libdesc $200 libref engine $8 IsDBMSLibname IsPreassigned $1
    tablename $50 /* metadata table names can be longer than $32 */
    ;
  keep libname libdesc libref engine ServerContext path_schema AuthDomain
    tableuri tablename IsPreassigned IsDBMSLibname id;
  call missing (of _all_);

  uri=symget('uri');
  rc= metadata_getattr(uri, "Name", libname);
  if rc <0 then do;
    put 'The library is not defined in this metadata repository.';
    stop;
  end;
  rc= metadata_getattr(uri, "Desc", libdesc);
  rc= metadata_getattr(uri, "Libref", libref);
  rc= metadata_getattr(uri, "Engine", engine);
  rc= metadata_getattr(uri, "IsDBMSLibname", IsDBMSLibname);
  rc= metadata_getattr(uri, "IsPreassigned", IsPreassigned);
  rc= metadata_getattr(uri, "Id", Id);

  /*** Get associated ServerContext ***/
  rc= metadata_getnasn(uri, "DeployedComponents", 1, serveruri);
  if rc > 0 then rc2= metadata_getattr(serveruri, "Name", ServerContext);
  else ServerContext='';

    /*** If the library is a DBMS library, get the Authentication Domain
          associated with the DBMS connection credentials ***/
  if IsDBMSLibname="1" and "&getauth"='YES' then do;
    rc= metadata_getnasn(uri, "LibraryConnection", 1, conn_uri);
    if rc>0 then do;
      rc2= metadata_getnasn(conn_uri, "Domain", 1, domainuri);
      if rc2>0 then rc3= metadata_getattr(domainuri, "Name", AuthDomain);
    end;
  end;

  /*** Get the path/database schema for this library ***/
  rc=metadata_getnasn(uri, "UsingPackages", 1, usingpkguri);
  if rc>0 then do;
    rc=metadata_resolve(usingpkguri,type,id);
    if type='Directory' then
      rc=metadata_getattr(usingpkguri, "DirectoryName", path_schema);
    else if type='DatabaseSchema' then
      rc=metadata_getattr(usingpkguri, "Name", path_schema);
    else path_schema="unknown";
  end;

  /*** Get the tables associated with this library ***/
  /*** If DBMS, tables are associated with DatabaseSchema ***/
  if type='DatabaseSchema' then do;
    t=1;
    ntab=metadata_getnasn(usingpkguri, "Tables", t, tableuri);
    if ntab>0 then do t=1 to ntab;
      tableuri='';
      tablename='';
      ntab=metadata_getnasn(usingpkguri, "Tables", t, tableuri);
      tabrc= metadata_getattr(tableuri, "Name", tablename);
      output;
    end;
    else put 'Library ' libname ' has no tables registered';
  end;
  else if type in ('Directory','SASLibrary') then do;
    t=1;
    ntab=metadata_getnasn(uri, "Tables", t, tableuri);
    if ntab>0 then do t=1 to ntab;
      tableuri='';
      tablename='';
      ntab=metadata_getnasn(uri, "Tables", t, tableuri);
      tabrc= metadata_getattr(tableuri, "Name", tablename);
      output;
    end;
    else put 'Library ' libname ' has no tables registered';
  end;
run;

proc sort;
by tablename tableuri;
run;

%mend mm_gettables;/**
  @file
  @brief Returns the metadata path and object from either the path or object
  @details Provide a metadata BIP tree path, or the uri for the bottom level
  folder, to obtain a dataset (<code>&outds</code>) containing both the path
  and uri.

  Usage:

      %mm_getTree(tree=/User Folders/sasdemo)


  @param tree= the BIP Tree folder path or uri
  @param outds= the dataset to create that contains the tree path & uri
  @param inds= an optional input dataset to augment with treepath & treeuri
  @param mDebug= set to 1 to show debug messages in the log

  @returns outds  dataset containing the following columns:
      - treeuri
      - treepath

  @version 9.2
  @author Allan Bowe

**/

%macro mm_getTree(
    tree=
    ,inds=
    ,outds=work.mm_getTree
    ,mDebug=0
)/*/STORE SOURCE*/;

%local mD;
%if &mDebug=1 %then %let mD=;
%else %let mD=%str(*);
%&mD.put Executing mm_getTree.sas;
%&mD.put _local_;

data &outds;
  length treeuri __parenturi __type __name $256 treepath $512;
%if %length(&inds)>0 %then %do;
  set &inds;
%end;
  __rc1=metadata_resolve("&tree",__type,treeuri);

  if __type='Tree' then do;
    __rc2=metadata_getattr(treeuri,"Name",__name);
    treepath=cats('/',__name);
    /* get parents */
    do while (metadata_getnasn(treeuri,"ParentTree",1,__parenturi)>0);
      __rc3=metadata_getattr(__parenturi,"Name",__name);
      treepath=cats('/',__name,treepath);
      treeuri=__parenturi;
    end;
    treeuri="&tree";
  end;
  else do;
    __rc2=metadata_pathobj(' ',"&tree",'Folder',__type,treeuri);
    treepath="&tree";
  end;

  &mD.put (_all_)(=);
  drop __:;
  if treeuri ne "" and treepath ne "" then output;
  stop;
run;
%mend mm_getTree;/**
  @file
  @brief Creates a dataset with all metadata types
  @details Usage:

    %mm_gettypes(outds=types)

  @param outds the dataset to create that contains the list of types
  @returns outds  dataset containing all types
  @warning The following filenames are created and then de-assigned:

      filename sxlemap clear;
      filename response clear;
      libname _XML_ clear;

  @version 9.2
  @author Allan Bowe

**/

%macro mm_gettypes(
    outds=work.mm_gettypes
)/*/STORE SOURCE*/;

* use a temporary fileref to hold the response;
filename response temp;
/* get list of libraries */
proc metadata in=
  '<GetTypes>
    <Types/>
    <NS>SAS</NS>
    <!-- specify the OMI_SUCCINCT flag -->
    <Flags>2048</Flags>
    <Options>
      <!-- include <REPOSID> XML element and a repository identifier -->
      <Reposid>$METAREPOSITORY</Reposid>
    </Options>
  </GetTypes>'
  out=response;
run;

/* write the response to the log for debugging */
data _null_;
  infile response lrecl=1048576;
  input;
  put _infile_;
run;

/* create an XML map to read the response */
filename sxlemap temp;
data _null_;
  file sxlemap;
  put '<SXLEMAP version="1.2" name="SASTypes"><TABLE name="SASTypes">';
  put '<TABLE-PATH syntax="XPath">//GetTypes/Types/Type</TABLE-PATH>';
  put '<COLUMN name="ID"><LENGTH>64</LENGTH>';
  put '<PATH syntax="XPath">//GetTypes/Types/Type/@Id</PATH></COLUMN>';
  put '<COLUMN name="Desc"><LENGTH>256</LENGTH>';
  put '<PATH syntax="XPath">//GetTypes/Types/Type/@Desc</PATH></COLUMN>';
  put '<COLUMN name="HasSubtypes">';
  put '<PATH syntax="XPath">//GetTypes/Types/Type/@HasSubtypes</PATH></COLUMN>';
  put '</TABLE></SXLEMAP>';
run;
libname _XML_ xml xmlfileref=response xmlmap=sxlemap;
/* sort the response by library name */
proc sort data=_XML_.sastypes out=&outds;
  by id;
run;


/* clear references */
filename sxlemap clear;
filename response clear;
libname _XML_ clear;

%mend mm_gettypes;/**
  @file mm_getusers.sas
  @brief Creates a table containing a list of all users
  @details Only shows a limited number of attributes as some sites will have a
  LOT of users.

  Usage:

      %mm_getusers()

  @param outds the dataset to create that contains the list of libraries

  @returns outds  dataset containing all users, with the following columns:
    - uri
    - name

  @warning The following filenames are created and then de-assigned:

      filename sxlemap clear;
      filename response clear;
      libname _XML_ clear;

  @version 9.3
  @author Allan Bowe

**/

%macro mm_getusers(
    outds=work.mm_getusers
)/*/STORE SOURCE*/;

filename response temp;
proc metadata in= '<GetMetadataObjects>
  <Reposid>$METAREPOSITORY</Reposid>
  <Type>Person</Type>
  <NS>SAS</NS>
  <Flags>0</Flags>
  <Options>
  <Templates>
  <Person Name=""/>
  </Templates>
  </Options>
  </GetMetadataObjects>'
  out=response;
run;

filename sxlemap temp;
data _null_;
  file sxlemap;
  put '<SXLEMAP version="1.2" name="SASObjects"><TABLE name="SASObjects">';
  put "<TABLE-PATH syntax='XPath'>/GetMetadataObjects/Objects/Person";
  put "</TABLE-PATH>";
  put '<COLUMN name="uri">';
  put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/Person/@Id</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>32</LENGTH>";
  put '</COLUMN><COLUMN name="name">';
  put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/Person/@Name</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>256</LENGTH>";
  put '</COLUMN></TABLE></SXLEMAP>';
run;
libname _XML_ xml xmlfileref=response xmlmap=sxlemap;

proc sort data= _XML_.SASObjects out=&outds;
  by name;
run;

filename sxlemap clear;
filename response clear;
libname _XML_ clear;

%mend mm_getusers;
/**
  @file
  @brief Retrieves properties of the SAS web app server
  @details
  Usage:

      %mm_getwebappsrvprops(outds= some_ds)
      data _null_;
        set some_ds(where=(name='webappsrv.server.url'));
        put value=;
      run;

  @param outds the dataset to create that contains the list of properties

  @returns outds  dataset containing all properties

  @warning The following filenames are created and then de-assigned:

      filename __in clear;
      filename __out clear;
      libname __shake clear;

  @version 9.4
  @author Allan Bowe https://github.com/sasjs/core

**/

%macro mm_getwebappsrvprops(
    outds= mm_getwebappsrvprops
)/*/STORE SOURCE*/;

filename __in temp lrecl=10000;
filename __out temp lrecl=10000;
filename __shake temp lrecl=10000;
data _null_ ;
  file __in ;
  put '<GetMetadataObjects>' ;
  put '<Reposid>$METAREPOSITORY</Reposid>' ;
  put '<Type>TextStore</Type>' ;
  put '<NS>SAS</NS>' ;
  put '<Flags>388</Flags>' ;
  put '<Options>' ;
  put '<XMLSelect search="TextStore[@Name='@@;
  put "'Public Configuration Properties']" @@;
  put '[Objects/SoftwareComponent[@ClassIdentifier=''webappsrv'']]' ;
  put '"/>';
  put '<Templates>' ;
  put '<TextStore StoredText="">' ;
  put '</TextStore>' ;
  put '</Templates>' ;
  put '</Options>' ;
  put '</GetMetadataObjects>' ;
run ;
proc metadata in=__in out=__out verbose;run;

/* find the beginning of the text */
%local start;
%let start=0;
data _null_;
  infile __out lrecl=10000;
  input;
  length cleartemplate $32000;
  cleartemplate=tranwrd(_infile_,'StoredText=""','');
  start=index(cleartemplate,'StoredText="');
  if start then do;
    call symputx("start",start+11+length('StoredText=""')-1);
    putlog cleartemplate ;
  end;
  stop;
run;
%put &=start;
%if &start>0 %then %do;
  /* read the content, byte by byte, resolving escaped chars */
  data _null_;
  length filein 8 fileid 8;
  filein = fopen("__out","I",1,"B");
  fileid = fopen("__shake","O",1,"B");
  rec = "20"x;
  length entity $6;
  do while(fread(filein)=0);
    x+1;
    if x>&start then do;
      rc = fget(filein,rec,1);
      if rec='"' then leave;
      else if rec="&" then do;
        entity=rec;
        do until (rec=";");
          if fread(filein) ne 0 then goto getout;
          rc = fget(filein,rec,1);
          entity=cats(entity,rec);
        end;
        select (entity);
          when ('&amp;' ) rec='&'  ;
          when ('&lt;'  ) rec='<'  ;
          when ('&gt;'  ) rec='>'  ;
          when ('&apos;') rec="'"  ;
          when ('&quot;') rec='"'  ;
          when ('&#x0a;') rec='0A'x;
          when ('&#x0d;') rec='0D'x;
          when ('&#36;' ) rec='$'  ;
          when ('&#x09;') rec='09'x;
          otherwise putlog "%str(WARN)ING: missing value for " entity=;
        end;
        rc =fput(fileid, substr(rec,1,1));
        rc =fwrite(fileid);
      end;
      else do;
        rc =fput(fileid,rec);
        rc =fwrite(fileid);
      end;
    end;
  end;
  getout:
  rc=fclose(filein);
  rc=fclose(fileid);
  run;
  data &outds ;
    infile __shake dlm='=' missover;
    length name $50 value $500;
    input name $ value $;
  run;
%end;
%else %do;
  %put NOTE: Unable to retrieve Web App Server Properties;
  data &outds;
    length name $50 value $500;
  run;
%end;

/* clear references */
filename __in clear;
filename __out clear;
filename __shake clear;

%mend mm_getwebappsrvprops;/**
  @file mm_spkexport.sas
  @brief Creates an batch spk export command
  @details Creates a script that will export everything in a metadata folder to
    a specified location.
    If you have XCMD enabled, then you can use mmx_spkexport (which performs
    the actual export)

    Note - the batch tools require a username and password.  For security,
    these are expected to have been provided in a protected directory.

  Usage:

      %* import the macros (or make them available some other way);
      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %* create sample text file as input to the macro;
      filename tmp temp;
      data _null_;
        file tmp;
        put '%let mmxuser="sasdemo";';
        put '%let mmxpass="Mars321";';
      run;

      filename myref "%sysfunc(pathname(work))/mmxexport.sh"
        permission='A::u::rwx,A::g::r-x,A::o::---';
      %mm_spkexport(metaloc=%str(/my/meta/loc)
          ,outref=myref
          ,secureref=tmp
          ,cmdoutloc=%str(/tmp)
      )

  Alternatively, call without inputs to create a function style output

      filename myref "/tmp/mmscript.sh"
        permission='A::u::rwx,A::g::r-x,A::o::---';
      %mm_spkexport(metaloc=%str(/my/meta/loc)
          outref=myref
          ,cmdoutloc=%str(/tmp)
          ,cmdoutname=mmx
      )

  You can then navigate and execute as follows:

      cd /tmp
      ./mmscript.sh "myuser" "mypass"


  <h4> SAS Macros </h4>
  @li mf_loc.sas
  @li mm_tree.sas
  @li mf_getuniquefileref.sas
  @li mf_isblank.sas
  @li mp_abort.sas

  @param metaloc= the metadata folder to export
  @param secureref= fileref containing the username / password (should point to
    a file in a secure location).  Leave blank to substitute $bash type vars.
  @param outref= fileref to which to write the command
  @param cmdoutloc= the directory to which the command will write the SPK
    (default=WORK)
  @param cmdoutname= the name of the spk / log files to create (will be
    identical just with .spk or .log extension)

  @version 9.4
  @author Allan Bowe

**/

%macro mm_spkexport(metaloc=
  ,secureref=
  ,outref=
  ,cmdoutloc=%sysfunc(pathname(work))
  ,cmdoutname=mmxport
);

%if &sysscp=WIN %then %do;
  %put %str(WARN)ING: the script has been written assuming a unix system;
  %put %str(WARN)ING- it will run anyway as should be easy to modify;
%end;

/* set creds */
%local mmxuser mmxpath;
%let mmxuser=$1;
%let mmxpass=$2;
%if %mf_isblank(&secureref)=0 %then %do;
  %inc &secureref/nosource;
%end;

/* setup metadata connection options */
%local host port platform_object_path connx_string;
%let host=%sysfunc(getoption(metaserver));
%let port=%sysfunc(getoption(metaport));
%let platform_object_path=%mf_loc(POF);

%let connx_string=%str(-host &host -port &port -user &mmxuser %trim(
  )-password &mmxpass);

%mm_tree(root=%str(&metaloc) ,types=EXPORTABLE ,outds=exportable)

%if %mf_isblank(&outref)=1 %then %let outref=%mf_getuniquefileref();

data _null_;
  set exportable end=last;
  file &outref lrecl=32767;
  length str $32767;
  if _n_=1 then do;
    put "cd ""&platform_object_path"" \";
    put "; ./ExportPackage &connx_string -disableX11 \";
    put " -package ""&cmdoutloc/&cmdoutname..spk"" \";
  end;
  str=' -objects '!!cats('"',path,'/',name,"(",publictype,')" \');
  put str;
  if last then put " -log ""&cmdoutloc/&cmdoutname..log"" 2>&1 ";
run;

%mp_abort(iftrue= (&syscc ne 0)
  ,mac=&sysmacroname
  ,msg=%str(syscc=&syscc)
)

%mend mm_spkexport;/**
  @file mm_tree.sas
  @brief Returns all folders / subfolder content for a particular root
  @details Shows all members and SubTrees for a particular root.

  Model:

      metauri char(64),
      name char(256) format=$256. informat=$256. label='name',
      path char(1024),
      publictype char(32),
      MetadataUpdated char(32),
      MetadataCreated char(32)

  Usage:

      %* load macros;
      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %* export everything;
      %mm_tree(root= ,outds=iwantthisdataset)

      %* export everything in a specific folder;
      %mm_tree(root=%str(/my/folder) ,outds=stuff)

      %* export only folders;
      %mm_tree(root=%str(/my/folder) ,types=Folder ,outds=stuf)

      %* show only exportable content;
      %mm_tree(root=%str(/) ,types=EXPORTABLE ,outds=exportable)

      %* with specific types;
      %mm_tree(root=%str(/my/folder)
        ,types=
            DeployedJob
            ExternalFile
            Folder
            Folder.SecuredData
            GeneratedTransform
            InformationMap.Relational
            Job
            Library
            Prompt
            StoredProcess
            Table
        ,outds=morestuff)

  <h4> SAS Macros </h4>
  @li mf_getquotedstr.sas
  @li mm_getpublictypes.sas
  @li mf_isblank.sas

  @param root= the parent folder under which to return all contents
  @param outds= the dataset to create that contains the list of directories
  @param types= Space-seperated, unquoted list of types for filtering the
    output.  Special types:

    * ALl - return all types (the default)
    * EXPORTABLE - return only the content types that can be exported in an SPK

  @version 9.4
  @author Allan Bowe

**/
%macro mm_tree(
    root=
    ,types=ALL
    ,outds=work.mm_tree
)/*/STORE SOURCE*/;
options noquotelenmax;

%if %mf_isblank(&root) %then %let root=/;

%if %str(&types)=EXPORTABLE %then %do;
  data;run;%local tempds; %let tempds=&syslast;
  %mm_getpublictypes(outds=&tempds)
  proc sql noprint;
  select publictype into: types separated by ' ' from &tempds;
  drop table &tempds;
%end;

* use a temporary fileref to hold the response;
filename response temp;
/* get list of libraries */
proc metadata in=
  '<GetMetadataObjects><Reposid>$METAREPOSITORY</Reposid>
    <Type>Tree</Type><Objects/><NS>SAS</NS>
    <Flags>384</Flags>
    <XMLSelect search="*[@TreeType=&apos;BIP Folder&apos;]"/>
    <Options/></GetMetadataObjects>'
    out=response;
run;
/*
data _null_;
  infile response;
  input;
  put _infile_;
  run;
*/

/* create an XML map to read the response */
filename sxlemap temp;
data _null_;
  file sxlemap;
  put '<SXLEMAP version="1.2" name="SASObjects"><TABLE name="SASObjects">';
  put "<TABLE-PATH syntax='XPath'>/GetMetadataObjects/Objects/Tree";
  put "</TABLE-PATH>";
  put '<COLUMN name="pathuri">';
  put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/Tree/@Id</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>64</LENGTH>";
  put '</COLUMN><COLUMN name="name">';
  put "<PATH syntax='XPath'>/GetMetadataObjects/Objects/Tree/@Name</PATH>";
  put "<TYPE>character</TYPE><DATATYPE>string</DATATYPE><LENGTH>256</LENGTH>";
  put '</COLUMN></TABLE></SXLEMAP>';
run;
libname _XML_ xml xmlfileref=response xmlmap=sxlemap;

data &outds;
  length metauri pathuri $64 name $256 path $1024
    publictype MetadataUpdated MetadataCreated $32;
  set _XML_.SASObjects;
  keep metauri name publictype MetadataUpdated MetadataCreated path;
  length parenturi pname $128 ;
  call missing(parenturi,pname);
  path=cats('/',name);
  /* get parents */
  tmpuri=pathuri;
  do while (metadata_getnasn(tmpuri,"ParentTree",1,parenturi)>0);
    rc=metadata_getattr(parenturi,"Name",pname);
    path=cats('/',pname,path);
    tmpuri=parenturi;
  end;

  if path=:"&root";

  %if "&types"="ALL" or ("&types" ne "ALL" and "&types" ne "Folder") %then %do;
    n=1;
    do while (metadata_getnasn(pathuri,"Members",n,metauri)>0);
      n+1;
      call missing(name,publictype,MetadataUpdated,MetadataCreated);
      rc=metadata_getattr(metauri,"Name", name);
      rc=metadata_getattr(metauri,"MetadataUpdated", MetadataUpdated);
      rc=metadata_getattr(metauri,"MetadataCreated", MetadataCreated);
      rc=metadata_getattr(metauri,"PublicType", PublicType);
    %if "&types" ne "ALL" %then %do;
      if publictype in (%mf_getquotedstr(&types)) then output;
    %end;
    %else output; ;
    end;
  %end;

  rc=metadata_resolve(pathuri,pname,tmpuri);
  metauri=cats('OMSOBJ:',pname,'\',pathuri);
  rc=metadata_getattr(metauri,"Name", name);
  rc=metadata_getattr(pathuri,"MetadataUpdated", MetadataUpdated);
  rc=metadata_getattr(pathuri,"MetadataCreated", MetadataCreated);
  rc=metadata_getattr(pathuri,"PublicType", PublicType);
  path=substr(path,1,length(path)-length(name)-1);
  if publictype ne '' then output;
run;

proc sort;
  by path;
run;

/* clear references */
filename sxlemap clear;
filename response clear;
libname _XML_ clear;

%mend mm_tree;
/**
  @file
  @brief Add or update an extension to an application component
  @details A SAS Application (SoftwareComponent) is a great place to store app
    specific parameters.  There are two main places those params can be stored:
    1) Configuration, and 2) Extensions.  The second location will enable end
    users to modify parameters even if they don't have the Configuration Manager
    plugin in SMC.  This macro can be used after creating an application with
    the mm_createapplication.sas macro.  If a parameter with the same name
    exists, it is updated.  If it does not, it is created.

  Usage:

    %mm_updateappextension(app=/my/metadata/path/myappname
      ,paramname=My Param
      ,paramvalue=My value
      ,paramdesc=some description)


  @param app= the BIP Tree folder path plus Application Name
  @param paramname= Parameter name
  @param paramvalue= Parameter value
  @param paramdesc= Parameter description

  @param frefin= change default inref if it clashes with an existing one
  @param frefout= change default outref if it clashes with an existing one
  @param mDebug= set to 1 to show debug messages in the log

  @version 9.4
  @author Allan Bowe

**/

%macro mm_updateappextension(app=
  ,paramname=
  ,paramvalue=
  ,paramdesc=Created by mm_updateappextension
  ,frefin=inmeta,frefout=outmeta
  , mdebug=0);


/* first, check if app (and param) exists */
%local appuri exturi;
%let appuri=stopifempty;
%let exturi=createifempty;

data _null_;
  format type uri tsuri value $200.;
  call missing (of _all_);
  paramname=symget('paramname');
  path="&app(Application)";
  /* first, find the STP ID */
  if metadata_pathobj("",path,"Application",type,uri)>0 then do;
    /* we have an app in this location! */
    call symputx('appuri',uri,'l');
    cnt=1;
    do while (metadata_getnasn(uri,"Extensions",cnt,tsuri)>0);
      rc=metadata_getattr(tsuri,"Name",value);
      put tsuri= value=;
      if value=paramname then do;
        putlog "&sysmacroname: found existing param - " tsuri;
        rc=metadata_getattr(tsuri,"Id",value);
        call symputx('exturi',value,'l');
        stop;
      end;
      cnt+1;
    end;
  end;
  else put (_all_)(=);
run;

%if &appuri=stopifempty %then %do;
  %put %str(WARN)ING:  &app.(Application) not found!;
  %return;
%end;

/* escape the description so it can be stored as XML  */
data _null_;
  length outstr $32767;
  outstr=symget('paramdesc');
  outstr=tranwrd(outstr,'&','&amp;');
  outstr=tranwrd(outstr,'<','&lt;');
  outstr=tranwrd(outstr,'>','&gt;');
  outstr=tranwrd(outstr,"'",'&apos;');
  outstr=tranwrd(outstr,'"','&quot;');
  outstr=tranwrd(outstr,'0A'x,'&#10;');
  outstr=tranwrd(outstr,'0D'x,'&#13;');
  outstr=tranwrd(outstr,'$','&#36;');
  call symputx('paramdesc',outstr,'l');
run;

filename &frefin temp;

%if &exturi=createifempty %then %do;
  /* write header XML */
  data _null_;
    file &frefin;
    pname=quote(trim(symget('paramname')));
    pdesc=quote(trim(symget('paramdesc')));
    pvalue=quote(trim(symget('paramvalue')));
    put "<UpdateMetadata><Reposid>$METAREPOSITORY</Reposid><Metadata>"/
        "  <SoftwareComponent id='&appuri' ><Extensions>" /
        '    <Extension Name=' pname ' Desc=' pdesc ' value= ' pvalue ' />' /
        '  </Extensions></SoftwareComponent>'/
        '</Metadata><NS>SAS</NS><Flags>268435456</Flags></UpdateMetadata>';
  run;

%end;
%else %do;
  data _null_;
    file &frefin;
    pdesc=quote(trim(symget('paramdesc')));
    pvalue=quote(trim(symget('paramvalue')));
    put "<UpdateMetadata><Reposid>$METAREPOSITORY</Reposid><Metadata>"/
        "  <Extension id='&exturi' Desc=" pdesc ' value= ' pvalue ' />' /
        '</Metadata><NS>SAS</NS><Flags>268435456</Flags></UpdateMetadata>';
  run;
%end;

filename &frefout temp;

proc metadata in= &frefin out=&frefout verbose;
run;

%if &mdebug=1 %then %do;
  /* write the response to the log for debugging */
  data _null_;
    infile &frefout lrecl=1048576;
    input;
    put _infile_;
  run;
%end;

%mend mm_updateappextension;/**
  @file
  @brief Update the TextStore in a Document with the same name
  @details Enables arbitrary content to be stored in a document object

  Usage:

    %mm_updatedocument(path=/my/metadata/path
      ,name=docname
      ,text="/file/system/some.txt")


  @param path= the BIP Tree folder path
  @param name=Document Name
  @param text=a source file containing the text to be added

  @param frefin= change default inref if it clashes with an existing one
  @param frefout= change default outref if it clashes with an existing one
  @param mDebug= set to 1 to show debug messages in the log

  @version 9.3
  @author Allan Bowe

**/

%macro mm_updatedocument(path=
  ,name=
  ,text=
  ,frefin=inmeta
  ,frefout=outmeta
  ,mdebug=0
);
/* first, check if STP exists */
%local tsuri;
%let tsuri=stopifempty ;

data _null_;
  format type uri tsuri value $200.;
  call missing (of _all_);
  path="&path/&name(Note)";
  /* first, find the STP ID */
  if metadata_pathobj("",path,"Note",type,uri)>0 then do;
    /* get sourcetext */
    cnt=1;
    do while (metadata_getnasn(uri,"Notes",cnt,tsuri)>0);
      rc=metadata_getattr(tsuri,"Name",value);
      put tsuri= value=;
      if value="&name" then do;
        /* found it! */
        rc=metadata_getattr(tsuri,"Id",value);
        call symputx('tsuri',value,'l');
        stop;
      end;
      cnt+1;
    end;
  end;
  else put (_all_)(=);
run;

%if &tsuri=stopifempty %then %do;
  %put %str(WARN)ING:  &path/&name.(Document) not found!;
  %return;
%end;

%if %length(&text)<2 %then %do;
  %put %str(WARN)ING:  No text supplied!!;
  %return;
%end;

filename &frefin temp recfm=n;

/* escape code so it can be stored as XML */
/* input file may be over 32k wide, so deal with one char at a time */
data _null_;
  file &frefin recfm=n;
  infile &text recfm=n;
  input instr $CHAR1. ;
  if _n_=1 then put "<UpdateMetadata><Reposid>$METAREPOSITORY</Reposid>
    <Metadata><TextStore id='&tsuri' StoredText='" @@;
  select (instr);
    when ('&') put '&amp;';
    when ('<') put '&lt;';
    when ('>') put '&gt;';
    when ("'") put '&apos;';
    when ('"') put '&quot;';
    when ('0A'x) put '&#x0a;';
    when ('0D'x) put '&#x0d;';
    when ('$') put '&#36;';
    otherwise put instr $CHAR1.;
  end;
run;

data _null_;
  file &frefin mod;
  put "'></TextStore></Metadata><NS>SAS</NS><Flags>268435456</Flags>
    </UpdateMetadata>";
run;


filename &frefout temp;

proc metadata in= &frefin
  %if &mdebug=1 %then out=&frefout verbose;
;
run;

%if &mdebug=1 %then %do;
  /* write the response to the log for debugging */
  data _null_;
    infile &frefout lrecl=1048576;
    input;
    put _infile_;
  run;
%end;

%mend mm_updatedocument;/**
  @file
  @brief Updates a type 2 stored process to run on STP or WKS context
  @details Only works on Type 2 (9.3 compatible) STPs

  Usage:

      %mm_updatestpservertype(target=/some/meta/path/myStoredProcess
        ,type=WKS)


  @param target= full path to the STP being deleted
  @param type= Either WKS or STP depending on whether Workspace or
    Stored Process type required

  @version 9.4
  @author Allan Bowe

**/

%macro mm_updatestpservertype(
  target=
  ,type=
)/*/STORE SOURCE*/;

/**
  * Check STP does exist
  */
%local cmtype;
data _null_;
  length type uri $256;
  rc=metadata_pathobj("","&target",'StoredProcess',type,uri);
  call symputx('cmtype',type,'l');
  call symputx('stpuri',uri,'l');
run;
%if &cmtype ne ClassifierMap %then %do;
  %put %str(WARN)ING: No Stored Process found at &target;
  %return;
%end;

%local newtype;
%if &type=WKS %then %let newtype=Wks;
%else %let newtype=Sps;

%local result;
%let result=NOT FOUND;
data _null_;
  length uri name value $256;
  n=1;
  do while(metadata_getnasn("&stpuri","Notes",n,uri)>0);
    n+1;
    rc=metadata_getattr(uri,"Name",name);
    if name='Stored Process' then do;
      rc = METADATA_SETATTR(uri,'StoredText'
        ,'<?xml version="1.0" encoding="UTF-8"?>'
        !!'<StoredProcess><ServerContext LogicalServerType="'!!"&newtype"
        !!'" OtherAllowed="false"/><ResultCapabilities Package="false" '
        !!' Streaming="true"/><OutputParameters/></StoredProcess>');
      if rc=0 then call symputx('result','SUCCESS');
      stop;
    end;
  end;
run;
%if &result=SUCCESS %then %put NOTE: SUCCESS: STP &target changed to &type type;
%else %put %str(ERR)OR: Issue with &sysmacroname;

%mend mm_updatestpservertype;
/**
  @file
  @brief Update the source code of a type 2 STP
  @details Uploads the contents of a text file or fileref to an existing type 2
    STP.  A type 2 STP has its source code saved in metadata.

  Usage:

      %mm_updatestpsourcecode(stp=/my/metadata/path/mystpname
        ,stpcode="/file/system/source.sas")

  @param [in] stp= the BIP Tree folder path plus Stored Process Name
  @param [in] stpcode= the source file (or fileref) containing the SAS code to load
    into the stp.  For multiple files, they should simply be concatenated first.
  @param [in] minify= set to YES in order to strip comments, blank lines, and CRLFs.

  @param frefin= deprecated - a unique fileref is now always used
  @param frefout= deprecated - a unique fileref is now always used
  @param mDebug= set to 1 to show debug messages in the log

  @version 9.3
  @author Allan Bowe

  <h4> SAS Macros </h4>
  @li mf_getuniquefileref.sas

**/

%macro mm_updatestpsourcecode(stp=
  ,stpcode=
  ,minify=NO
  ,mdebug=0
  /* deprecated */
  ,frefin=inmeta
  ,frefout=outmeta
);

%if &frefin ne inmeta or &frefout ne outmeta %then %do;
  %put %str(WARN)ING: the frefin and frefout parameters will be deprecated in
    an upcoming release.;
%end;

/* first, check if STP exists */
%local tsuri;
%let tsuri=stopifempty ;

data _null_;
  format type uri tsuri value $200.;
  call missing (of _all_);
  path="&stp.(StoredProcess)";
  /* first, find the STP ID */
  if metadata_pathobj("",path,"StoredProcess",type,uri)>0 then do;
    /* get sourcecode */
    cnt=1;
    do while (metadata_getnasn(uri,"Notes",cnt,tsuri)>0);
      rc=metadata_getattr(tsuri,"Name",value);
      put tsuri= value=;
      if value="SourceCode" then do;
        /* found it! */
        rc=metadata_getattr(tsuri,"Id",value);
        call symputx('tsuri',value,'l');
        stop;
      end;
      cnt+1;
    end;
  end;
  else put (_all_)(=);
run;

%if &tsuri=stopifempty %then %do;
  %put %str(WARN)ING:  &stp.(StoredProcess) not found!;
  %return;
%end;

%if %length(&stpcode)<2 %then %do;
  %put %str(WARN)ING:  No SAS code supplied!!;
  %return;
%end;

%local frefin frefout;
%let frefin=%mf_getuniquefileref();
%let frefout=%mf_getuniquefileref();

/* write header XML */
data _null_;
  file &frefin;
  put "<UpdateMetadata><Reposid>$METAREPOSITORY</Reposid>
    <Metadata><TextStore id='&tsuri' StoredText='";
run;

/* escape code so it can be stored as XML */
/* write contents */
%if %length(&stpcode)>2 %then %do;
  data _null_;
    file &frefin lrecl=32767 mod;
    infile &stpcode lrecl=32767;
    length outstr $32767;
    input outstr ;
    /* escape code so it can be stored as XML */
    outstr=tranwrd(_infile_,'&','&amp;');
    outstr=tranwrd(outstr,'<','&lt;');
    outstr=tranwrd(outstr,'>','&gt;');
    outstr=tranwrd(outstr,"'",'&apos;');
    outstr=tranwrd(outstr,'"','&quot;');
    outstr=tranwrd(outstr,'0A'x,'&#x0a;');
    outstr=tranwrd(outstr,'0D'x,'&#x0d;');
    outstr=tranwrd(outstr,'$','&#36;');
    %if &minify=YES %then %do;
      outstr=cats(outstr);
      if outstr ne '';
      if not (outstr=:'/*' and subpad(left(reverse(outstr)),1,2)='/*');
    %end;
    outstr=trim(outstr);
    put outstr '&#10;';
  run;
%end;

data _null_;
  file &frefin mod;
  put "'></TextStore></Metadata><NS>SAS</NS><Flags>268435456</Flags>
    </UpdateMetadata>";
run;

proc metadata in= &frefin out=&frefout;
run;

%if &mdebug=1 %then %do;
  /* write the response to the log for debugging */
  data _null_;
    infile &frefout lrecl=32767;
    input;
    put _infile_;
  run;
%end;
%else %do;
  filename &frefin clear;
  filename &frefout clear;
%end;

%mend mm_updatestpsourcecode;/**
  @file mm_webout.sas
  @brief Send data to/from SAS Stored Processes
  @details This macro should be added to the start of each Stored Process,
  **immediately** followed by a call to:

        %mm_webout(FETCH)

    This will read all the input data and create same-named SAS datasets in the
    WORK library.  You can then insert your code, and send data back using the
    following syntax:

        data some datasets; * make some data ;
        retain some columns;
        run;

        %mm_webout(OPEN)
        %mm_webout(ARR,some)  * Array format, fast, suitable for large tables ;
        %mm_webout(OBJ,datasets) * Object format, easier to work with ;

    Finally, wrap everything up send some helpful system variables too

        %mm_webout(CLOSE)


  @param action Either FETCH, OPEN, ARR, OBJ or CLOSE
  @param ds The dataset to send back to the frontend
  @param dslabel= value to use instead of the real name for sending to JSON
  @param fmt=(Y) Set to N to send back unformatted values
  @param fref=(_webout) The fileref to which to write the JSON

  @version 9.3
  @author Allan Bowe

**/
%macro mm_webout(action,ds,dslabel=,fref=_webout,fmt=Y);
%global _webin_file_count _webin_fileref1 _webin_name1 _program _debug
  sasjs_tables;
%local i tempds jsonengine;

/* see https://github.com/sasjs/core/issues/41 */
%if "%upcase(&SYSENCODING)" ne "UTF-8" %then %let jsonengine=PROCJSON;
%else %let jsonengine=DATASTEP;


%if &action=FETCH %then %do;
  %if %str(&_debug) ge 131 %then %do;
    options mprint notes mprintnest;
  %end;
  %let _webin_file_count=%eval(&_webin_file_count+0);
  /* now read in the data */
  %do i=1 %to &_webin_file_count;
    %if &_webin_file_count=1 %then %do;
      %let _webin_fileref1=&_webin_fileref;
      %let _webin_name1=&_webin_name;
    %end;
    data _null_;
      infile &&_webin_fileref&i termstr=crlf;
      input;
      call symputx('input_statement',_infile_);
      putlog "&&_webin_name&i input statement: "  _infile_;
      stop;
    data &&_webin_name&i;
      infile &&_webin_fileref&i firstobs=2 dsd termstr=crlf encoding='utf-8';
      input &input_statement;
      %if %str(&_debug) ge 131 %then %do;
        if _n_<20 then putlog _infile_;
      %end;
    run;
    %let sasjs_tables=&sasjs_tables &&_webin_name&i;
  %end;
%end;

%else %if &action=OPEN %then %do;
  /* fix encoding */
  OPTIONS NOBOMFILE;

  /**
    * check xengine type to avoid the below err message:
    * > Function is only valid for filerefs using the CACHE access method.
    */
  data _null_;
    set sashelp.vextfl(where=(fileref="_WEBOUT"));
    if xengine='STREAM' then do;
      rc=stpsrv_header('Content-type',"text/html; encoding=utf-8");
    end;
  run;

  /* setup json */
  data _null_;file &fref encoding='utf-8';
  %if %str(&_debug) ge 131 %then %do;
    put '>>weboutBEGIN<<';
  %end;
    put '{"START_DTTM" : "' "%sysfunc(datetime(),datetime20.3)" '"';
  run;

%end;

%else %if &action=ARR or &action=OBJ %then %do;
  %mp_jsonout(&action,&ds,dslabel=&dslabel,fmt=&fmt,jref=&fref
    ,engine=&jsonengine,dbg=%str(&_debug)
  )
%end;
%else %if &action=CLOSE %then %do;
  %if %str(&_debug) ge 131 %then %do;
    /* if debug mode, send back first 10 records of each work table also */
    options obs=10;
    data;run;%let tempds=%scan(&syslast,2,.);
    ods output Members=&tempds;
    proc datasets library=WORK memtype=data;
    %local wtcnt;%let wtcnt=0;
    data _null_;
      set &tempds;
      if not (upcase(name) =:"DATA"); /* ignore temp datasets */
      i+1;
      call symputx('wt'!!left(i),name,'l');
      call symputx('wtcnt',i,'l');
    data _null_; file &fref mod encoding='utf-8';
      put ",""WORK"":{";
    %do i=1 %to &wtcnt;
      %let wt=&&wt&i;
      proc contents noprint data=&wt
        out=_data_ (keep=name type length format:);
      run;%let tempds=%scan(&syslast,2,.);
      data _null_; file &fref mod encoding='utf-8';
        dsid=open("WORK.&wt",'is');
        nlobs=attrn(dsid,'NLOBS');
        nvars=attrn(dsid,'NVARS');
        rc=close(dsid);
        if &i>1 then put ','@;
        put " ""&wt"" : {";
        put '"nlobs":' nlobs;
        put ',"nvars":' nvars;
      %mp_jsonout(OBJ,&tempds,jref=&fref,dslabel=colattrs,engine=&jsonengine)
      %mp_jsonout(OBJ,&wt,jref=&fref,dslabel=first10rows,engine=&jsonengine)
      data _null_; file &fref mod encoding='utf-8';
        put "}";
    %end;
    data _null_; file &fref mod encoding='utf-8';
      put "}";
    run;
  %end;
  /* close off json */
  data _null_;file &fref mod encoding='utf-8';
    _PROGRAM=quote(trim(resolve(symget('_PROGRAM'))));
    put ",""SYSUSERID"" : ""&sysuserid"" ";
    put ",""MF_GETUSER"" : ""%mf_getuser()"" ";
    put ",""_DEBUG"" : ""&_debug"" ";
    _METAUSER=quote(trim(symget('_METAUSER')));
    put ",""_METAUSER"": " _METAUSER;
    _METAPERSON=quote(trim(symget('_METAPERSON')));
    put ',"_METAPERSON": ' _METAPERSON;
    put ',"_PROGRAM" : ' _PROGRAM ;
    put ",""SYSCC"" : ""&syscc"" ";
    put ",""SYSERRORTEXT"" : ""&syserrortext"" ";
    put ",""SYSHOSTNAME"" : ""&syshostname"" ";
    put ",""SYSJOBID"" : ""&sysjobid"" ";
    put ",""SYSSCPL"" : ""&sysscpl"" ";
    put ",""SYSSITE"" : ""&syssite"" ";
    sysvlong=quote(trim(symget('sysvlong')));
    put ',"SYSVLONG" : ' sysvlong;
    put ",""SYSWARNINGTEXT"" : ""&syswarningtext"" ";
    put ',"END_DTTM" : "' "%sysfunc(datetime(),datetime20.3)" '" ';
    put "}" @;
  %if %str(&_debug) ge 131 %then %do;
    put '>>weboutEND<<';
  %end;
  run;
%end;

%mend mm_webout;
/**
  @file
  @brief Deletes a metadata folder
  @details Deletes a metadata folder (and contents) using the batch tools, as
    documented here:
    https://documentation.sas.com/?docsetId=bisag&docsetTarget=p0zqp8fmgs4o0kn1tt7j8ho829fv.htm&docsetVersion=9.4&locale=en

  Usage:

    %mmx_deletemetafolder(loc=/some/meta/folder,user=sasdemo,pass=mars345)

  <h4> SAS Macros </h4>
  @li mf_loc.sas

  @param loc= the metadata folder to delete
  @param user= username
  @param pass= password

  @version 9.4
  @author Allan Bowe

**/

%macro mmx_deletemetafolder(loc=,user=,pass=);

%local host port path connx_string;
%let host=%sysfunc(getoption(metaserver));
%let port=%sysfunc(getoption(metaport));
%let path=%mf_loc(POF)/tools;

%let connx_string= -host &host -port &port -user '&user' -password '&pass';
/* remove directory */
data _null_;
  infile " &path/sas-delete-objects &connx_string ""&loc"" -deleteContents 2>&1"
    pipe lrecl=10000;
  input;
  putlog _infile_;
run;

%mend mmx_deletemetafolder;/**
  @file mmx_spkexport.sas
  @brief Exports everything in a particular metadata folder
  @details Will export everything in a metadata folder to a specified location.
    Note - the batch tools require a username and password.  For security,
    these are expected to have been provided in a protected directory.

Usage:

    %* import the macros (or make them available some other way);
    filename mc url "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
    %inc mc;

    %* create sample text file as input to the macro;
    filename tmp temp;
    data _null_;
      file tmp;
      put '%let mmxuser=sasdemo;';
      put '%let mmxpass=Mars321';
    run;

    filename outref "%sysfunc(pathname(work))";
    %mmx_spkexport(
        metaloc=%str(/30.Projects/3001.Internal/300115.DataController/dc1)
        ,secureref=tmp
        ,outspkpath=%str(/tmp)
    )

  <h4> SAS Macros </h4>
  @li mf_loc.sas
  @li mm_tree.sas
  @li mf_getuniquefileref.sas
  @li mp_abort.sas

  @param metaloc= the metadata folder to export
  @param secureref= fileref containing the username / password (should point to
    a file in a secure location)
  @param outspkname= name of the spk to be created (default is mmxport).
  @param outspkpath= directory in which to create the SPK.  Default is WORK.

  @version 9.4
  @author Allan Bowe

**/

%macro mmx_spkexport(metaloc=
  ,secureref=
  ,outspkname=mmxport
  ,outspkpath=%sysfunc(pathname(work))
);

%local host port platform_object_path connx_string;
%let host=%sysfunc(getoption(metaserver));
%let port=%sysfunc(getoption(metaport));
%let platform_object_path=%mf_loc(POF);

/* get creds */
%inc &secureref/nosource;

%let connx_string=
  %str(-host &host -port &port -user '&mmxuser' -password '&mmxpass');

%mm_tree(root=%str(&metaloc) ,types=EXPORTABLE ,outds=exportable)

%local fref1;
%let fref1=%mf_getuniquefileref();
data ;
  set exportable end=last;
  file &fref1 lrecl=32767;
  length str $32767;
  if _n_=1 then do;
    put 'data _null_;';
    put 'infile "cd ""&platform_object_path"" %trim(';
    put ') cd ""&platform_object_path"" %trim(';
    put '); ./ExportPackage &connx_string -disableX11 %trim(';
    put ') -package ""&outspkpath/&outspkname..spk"" %trim(';
  end;
  str=') -objects '!!cats('""',path,'/',name,"(",publictype,')"" %trim(');
  put str;
  if last then do;
    put ') -log ""&outspkpath/&outspkname..log"" 2>&1" pipe lrecl=10000;';
    put 'input;putlog _infile_;run;';
  end;
run;

%mp_abort(iftrue= (&syscc ne 0)
  ,mac=&sysmacroname
  ,msg=%str(syscc=&syscc)
)

%inc &fref1;

%mend mmx_spkexport;/**
  @file
  @brief Send data to/from @sasjs/server
  @details This macro should be added to the start of each web service,
  **immediately** followed by a call to:

        %ms_webout(FETCH)

    This will read all the input data and create same-named SAS datasets in the
    WORK library.  You can then insert your code, and send data back using the
    following syntax:

        data some datasets; * make some data ;
          retain some columns;
        run;

        %ms_webout(OPEN)
        %ms_webout(ARR,some)  * Array format, fast, suitable for large tables ;
        %ms_webout(OBJ,datasets) * Object format, easier to work with ;
        %ms_webout(CLOSE)


  @param action Either FETCH, OPEN, ARR, OBJ or CLOSE
  @param ds The dataset to send back to the frontend
  @param dslabel= value to use instead of the real name for sending to JSON
  @param fmt=(Y) Set to N to send back unformatted values
  @param fref=(_webout) The fileref to which to write the JSON

  <h4> SAS Macros </h4>
  @li mp_jsonout.sas
  @li mf_getuser.sas

  <h4> Related Macros </h4>
  @li mv_webout.sas
  @li mm_webout.sas

  @version 9.3
  @author Allan Bowe

**/

%macro ms_webout(action,ds,dslabel=,fref=_webout,fmt=Y);
%global _webin_file_count _webin_fileref1 _webin_name1 _program _debug
  sasjs_tables;

%local i tempds;
%let action=%upcase(&action);

%if &action=FETCH %then %do;
  %if %str(&_debug) ge 131 %then %do;
    options mprint notes mprintnest;
  %end;
  %let _webin_file_count=%eval(&_webin_file_count+0);
  /* now read in the data */
  %do i=1 %to &_webin_file_count;
    %if &_webin_file_count=1 %then %do;
      %let _webin_fileref1=&_webin_fileref;
      %let _webin_name1=&_webin_name;
    %end;
    data _null_;
      infile &&_webin_fileref&i termstr=crlf;
      input;
      call symputx('input_statement',_infile_);
      putlog "&&_webin_name&i input statement: "  _infile_;
      stop;
    data &&_webin_name&i;
      infile &&_webin_fileref&i firstobs=2 dsd termstr=crlf encoding='utf-8';
      input &input_statement;
      %if %str(&_debug) ge 131 %then %do;
        if _n_<20 then putlog _infile_;
      %end;
    run;
    %let sasjs_tables=&sasjs_tables &&_webin_name&i;
  %end;
%end;

%else %if &action=OPEN %then %do;
  /* fix encoding */
  OPTIONS NOBOMFILE;

  /* setup json */
  data _null_;file &fref encoding='utf-8' termstr=lf;
  %if %str(&_debug) ge 131 %then %do;
    put '>>weboutBEGIN<<';
  %end;
    put '{"SYSDATE" : "' "&SYSDATE" '"';
    put ',"SYSTIME" : "' "&SYSTIME" '"';
  run;

%end;

%else %if &action=ARR or &action=OBJ %then %do;
  %mp_jsonout(&action,&ds,dslabel=&dslabel,fmt=&fmt,jref=&fref
    ,engine=DATASTEP,dbg=%str(&_debug)
  )
%end;
%else %if &action=CLOSE %then %do;
  %if %str(&_debug) ge 131 %then %do;
    /* if debug mode, send back first 10 records of each work table also */
    options obs=10;
    data;run;%let tempds=%scan(&syslast,2,.);
    ods output Members=&tempds;
    proc datasets library=WORK memtype=data;
    %local wtcnt;%let wtcnt=0;
    data _null_;
      set &tempds;
      if not (upcase(name) =:"DATA"); /* ignore temp datasets */
      i+1;
      call symputx('wt'!!left(i),name,'l');
      call symputx('wtcnt',i,'l');
    data _null_; file &fref mod encoding='utf-8' termstr=lf;
      put ",""WORK"":{";
    %do i=1 %to &wtcnt;
      %let wt=&&wt&i;
      proc contents noprint data=&wt
        out=_data_ (keep=name type length format:);
      run;%let tempds=%scan(&syslast,2,.);
      data _null_; file &fref mod encoding='utf-8' termstr=lf;
        dsid=open("WORK.&wt",'is');
        nlobs=attrn(dsid,'NLOBS');
        nvars=attrn(dsid,'NVARS');
        rc=close(dsid);
        if &i>1 then put ','@;
        put " ""&wt"" : {";
        put '"nlobs":' nlobs;
        put ',"nvars":' nvars;
      %mp_jsonout(OBJ,&tempds,jref=&fref,dslabel=colattrs,engine=DATASTEP)
      %mp_jsonout(OBJ,&wt,jref=&fref,dslabel=first10rows,engine=DATASTEP)
      data _null_; file &fref mod encoding='utf-8' termstr=lf;
        put "}";
    %end;
    data _null_; file &fref mod encoding='utf-8' termstr=lf termstr=lf;
      put "}";
    run;
  %end;
  /* close off json */
  data _null_;file &fref mod encoding='utf-8' termstr=lf;
    _PROGRAM=quote(trim(resolve(symget('_PROGRAM'))));
    put ",""SYSUSERID"" : ""&sysuserid"" ";
    put ",""MF_GETUSER"" : ""%mf_getuser()"" ";
    put ",""_DEBUG"" : ""&_debug"" ";
    put ',"_PROGRAM" : ' _PROGRAM ;
    put ",""SYSCC"" : ""&syscc"" ";
    put ",""SYSERRORTEXT"" : ""&syserrortext"" ";
    SYSHOSTINFOLONG=quote(trim(symget('SYSHOSTINFOLONG')));
    put ',"SYSHOSTINFOLONG" : ' SYSHOSTINFOLONG;
    put ",""SYSHOSTNAME"" : ""&syshostname"" ";
    put ",""SYSPROCESSID"" : ""&SYSPROCESSID"" ";
    put ",""SYSPROCESSMODE"" : ""&SYSPROCESSMODE"" ";
    length SYSPROCESSNAME $512;
    SYSPROCESSNAME=quote(urlencode(cats(SYSPROCESSNAME)));
    put ",""SYSPROCESSNAME"" : " SYSPROCESSNAME;
    put ",""SYSJOBID"" : ""&sysjobid"" ";
    put ",""SYSSCPL"" : ""&sysscpl"" ";
    put ",""SYSSITE"" : ""&syssite"" ";
    put ",""SYSTCPIPHOSTNAME"" : ""&SYSTCPIPHOSTNAME"" ";
    sysvlong=quote(trim(symget('sysvlong')));
    put ',"SYSVLONG" : ' sysvlong;
    put ",""SYSWARNINGTEXT"" : ""&syswarningtext"" ";
    put ',"END_DTTM" : "' "%sysfunc(datetime(),datetime20.3)" '" ';
    length autoexec $512;
    autoexec=quote(urlencode(trim(getoption('autoexec'))));
    put ',"AUTOEXEC" : ' autoexec;
    memsize="%sysfunc(INPUTN(%sysfunc(getoption(memsize)), best.),sizekmg.)";
    memsize=quote(cats(memsize));
    put ',"MEMSIZE" : ' memsize;
    put "}" @;
  %if %str(&_debug) ge 131 %then %do;
    put '>>weboutEND<<';
  %end;
  run;
%end;

%mend ms_webout;
/**
  @file
  @brief Checks whether a file exists in SAS Drive
  @details Returns 1 if the file exists, and 0 if it doesn't.  Works by
  attempting to assign a fileref with the filesrvc engine.  If not found, the
  syscc is automatically set to a non zero value - so in this case it is reset.
  To avoid hiding issues, there is therefore a test at the start to ensure the
  syscc is zero.

  Usage:

      %put %mfv_existfile(/does/exist.txt);
      %put %mfv_existfile(/does/not/exist.txt);

  @param filepath The full path to the file on SAS drive (eg /Public/myfile.txt)

  <h4> SAS Macros </h4>
  @li mf_abort.sas
  @li mf_getuniquefileref.sas

  <h4> Related Macros </h4>
  @li mfv_existfolder.sas

  @version 3.5
  @author [Allan Bowe](https://www.linkedin.com/in/allanbowe/)
**/

%macro mfv_existfile(filepath
)/*/STORE SOURCE*/;

  %mf_abort(
    iftrue=(&syscc ne 0),
    msg=Cannot enter mfv_existfile.sas with syscc=&syscc
  )

  %local fref rc path name;
  %let fref=%mf_getuniquefileref();
  %let name=%scan(&filepath,-1,/);
  %let path=%substr(&filepath,1,%length(&filepath)-%length(&name)-1);

  %if %sysfunc(filename(fref,,filesrvc,folderPath="&path" filename="&name"))=0
  %then %do;
    %sysfunc(fexist(&fref))
    %let rc=%sysfunc(filename(fref));
  %end;
  %else %do;
    0
    %let syscc=0;
  %end;

%mend mfv_existfile;/**
  @file
  @brief Checks whether a folder exists in SAS Drive
  @details Returns 1 if the folder exists, and 0 if it doesn't.  Works by
  attempting to assign a fileref with the filesrvc engine.  If not found, the
  syscc is automatically set to a non zero value - so in this case it is reset.
  To avoid hiding issues, there is therefore a test at the start to ensure the
  syscc is zero.

  Usage:

      %put %mfv_existfolder(/does/exist);
      %put %mfv_existfolder(/does/not/exist);

  @param path The path to the folder on SAS drive

  <h4> SAS Macros </h4>
  @li mf_abort.sas
  @li mf_getuniquefileref.sas

  <h4> Related Macros </h4>
  @li mfv_existfile.sas

  @version 3.5
  @author [Allan Bowe](https://www.linkedin.com/in/allanbowe/)
**/

%macro mfv_existfolder(path
)/*/STORE SOURCE*/;

  %mf_abort(
    iftrue=(&syscc ne 0),
    msg=Cannot enter mfv_existfolder.sas with syscc=&syscc
  )

  %local fref rc;
  %let fref=%mf_getuniquefileref();

  %if %sysfunc(filename(fref,,filesrvc,folderPath="&path"))=0 %then %do;
    1
    %let rc=%sysfunc(filename(fref));
  %end;
  %else %do;
    0
    %let syscc=0;
  %end;

%mend mfv_existfolder;/**
  @file
  @brief Creates a file in SAS Drive
  @details Creates a file in SAS Drive and adds the appropriate content type.
  If the parent folder does not exist, it is created.

  Usage:

      filename myfile temp;
      data _null_;
        file myfile;
        put 'something';
      run;
      %mv_createfile(path=/Public/temp,name=newfile.txt,inref=myfile)


  @param [in] path= The parent folder in which to create the file
  @param [in] name= The name of the file to be created
  @param [in] inref= The fileref pointing to the file to be uploaded
  @param [in] intype= (BINARY) The type of the input data.  Valid values:
    @li BINARY File is copied byte for byte using the mp_binarycopy.sas macro.
    @li BASE64 File will be first decoded using the mp_base64.sas macro, then
      loaded byte by byte to SAS Drive.
  @param [in] contentdisp= (inline) Content Disposition. Example values:
    @li inline
    @li attachment

  @param [in] access_token_var= The global macro variable to contain the access
    token, if using authorization_code grant type.
  @param [in] grant_type= (sas_services) Valid values are:
    @li password
    @li authorization_code
    @li sas_services

  @param [in] mdebug= (0) Set to 1 to enable DEBUG messages

  @version VIYA V.03.05
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mf_getuniquefileref.sas
  @li mf_isblank.sas
  @li mp_abort.sas
  @li mp_base64copy.sas
  @li mp_binarycopy.sas
  @li mv_createfolder.sas

**/

%macro mv_createfile(path=
    ,name=
    ,inref=
    ,intype=BINARY
    ,contentdisp=inline
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,mdebug=0
  );
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
  %let oauth_bearer=oauth_bearer=sas_services;
  %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%mp_abort(iftrue=(%mf_isblank(&path)=1 or %length(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mp_abort(iftrue=(%mf_isblank(&name)=1 or %length(&name)=1)
  ,mac=&sysmacroname
  ,msg=%str(name value with length >1 must be provided)
)

/* create folder if it does not already exist */
%mv_createfolder(path=&path
  ,access_token_var=&access_token_var
  ,grant_type=&grant_type
  ,mdebug=&mdebug
)

/* create file with relevant options */
%local fref;
%let fref=%mf_getuniquefileref();
filename &fref filesrvc
  folderPath="&path"
  filename="&name"
  cdisp="&contentdisp"
  lrecl=1048544;

%if &intype=BINARY %then %do;
  %mp_binarycopy(inref=&inref, outref=&fref)
%end;
%else %if &intype=BASE64 %then %do;
  %mp_base64copy(inref=&inref, outref=&fref, action=DECODE)
%end;

filename &fref clear;

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

%put &sysmacroname: File &name successfully created in &path;
%put &sysmacroname:;%put;
%put    &base_uri/SASJobExecution?_file=&path/&name;%put;
%put &sysmacroname:;

%mend mv_createfile;/**
  @file mv_createfolder.sas
  @brief Creates a viya folder if that folder does not already exist
  @details Creates a viya folder by checking if each parent folder exists, and
  recursively creating children if needed.
  Usage:

      %mv_createfolder(path=/Public)


  @param [in] path= The full path of the folder to be created
  @param [in] access_token_var= The global macro variable to contain the access
    token, if using authorization_code grant type.
  @param [in] grant_type= (sas_services) Valid values are:
    @li password
    @li authorization_code
    @li sas_services

  @param [in] mdebug=(0) set to 1 to enable DEBUG messages

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_isblank.sas
  @li mf_getplatform.sas
  @li mfv_existfolder.sas


**/

%macro mv_createfolder(path=
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,mdebug=0
  );
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

%if %mfv_existfolder(&path)=1 %then %do;
  %put &sysmacroname: &path already exists;
  %return;
%end;

%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
  %let oauth_bearer=oauth_bearer=sas_services;
  %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%mp_abort(iftrue=(%mf_isblank(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mp_abort(iftrue=(%length(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)

options noquotelenmax;

%local subfolder_cnt; /* determine the number of subfolders */
%let subfolder_cnt=%sysfunc(countw(&path,/));

%local href; /* resource address (none for root) */
%let href="/folders/folders?parentFolderUri=/folders/folders/none";

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

%local x newpath subfolder;
%do x=1 %to &subfolder_cnt;
  %let subfolder=%scan(&path,&x,%str(/));
  %let newpath=&newpath/&subfolder;

  %local fname1;
  %let fname1=%mf_getuniquefileref();

  %put &sysmacroname checking to see if &newpath exists;
  proc http method='GET' out=&fname1 &oauth_bearer
      url="&base_uri/folders/folders/@item?path=&newpath";
  %if &grant_type=authorization_code %then %do;
      headers "Authorization"="Bearer &&&access_token_var";
  %end;
  run;
  %local libref1;
  %let libref1=%mf_getuniquelibref();
  libname &libref1 JSON fileref=&fname1;
  %mp_abort(
    iftrue=(
      &SYS_PROCHTTP_STATUS_CODE ne 200 and &SYS_PROCHTTP_STATUS_CODE ne 404
    )
    ,mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
  %if &mdebug=1 %then %do;
    %put &sysmacroname following check to see if &newpath exists:;
    %put _local_;
    data _null_;
      set &fname1;
      input;
      putlog _infile_;
    run;
  %end;
  %if &SYS_PROCHTTP_STATUS_CODE=200 %then %do;
    %*put &sysmacroname &newpath exists so grab the follow on link ;
    data _null_;
      set &libref1..links;
      if rel='createChild' then
        call symputx('href',quote(cats("&base_uri",href)),'l');
    run;
  %end;
  %else %if &SYS_PROCHTTP_STATUS_CODE=404 %then %do;
    %put &sysmacroname &newpath not found - creating it now;
    %local fname2;
    %let fname2=%mf_getuniquefileref();
    data _null_;
      length json $1000;
      json=cats("'"
        ,'{"name":'
        ,quote(trim(symget('subfolder')))
        ,',"description":'
        ,quote("&subfolder, created by &sysmacroname")
        ,',"type":"folder"}'
        ,"'"
      );
      call symputx('json',json,'l');
    run;

    proc http method='POST'
        in=&json
        out=&fname2
        &oauth_bearer
        url=%unquote(%superq(href));
        headers
      %if &grant_type=authorization_code %then %do;
                "Authorization"="Bearer &&&access_token_var"
      %end;
                'Content-Type'='application/vnd.sas.content.folder+json'
                'Accept'='application/vnd.sas.content.folder+json';
    run;
    %put &=SYS_PROCHTTP_STATUS_CODE;
    %put &=SYS_PROCHTTP_STATUS_PHRASE;
    %mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 201)
      ,mac=&sysmacroname
      ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
    )
    %local libref2;
    %let libref2=%mf_getuniquelibref();
    libname &libref2 JSON fileref=&fname2;
    %put &sysmacroname &newpath now created. Grabbing the follow on link ;
    data _null_;
      set &libref2..links;
      if rel='createChild' then do;
        call symputx('href',quote(cats("&base_uri",href)),'l');
        &dbg put (_all_)(=);
      end;
    run;

    libname &libref2 clear;
    filename &fname2 clear;
  %end;
  filename &fname1 clear;
  libname &libref1 clear;
%end;
%mend mv_createfolder;/**
  @file
  @brief Creates a Viya Job
  @details
  Code is passed in as one or more filerefs.

      %* Step 1 - compile macros ;
      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %* Step 2 - Create some SAS code and add it to a job;
      filename ft15f001 temp;
      parmcards4;
          data some_code;
            set sashelp.class;
          run;
      ;;;;
      %mv_createjob(path=/Public/app/sasjstemp/jobs/myjobs,name=myjob)

  The path to the job will then be shown in the log, eg as follows:

  ![viya job location](https://i.imgur.com/XRUDHgA.png)


  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mv_createfolder.sas
  @li mf_getuniquelibref.sas
  @li mf_getuniquefileref.sas
  @li mf_getplatform.sas
  @li mf_isblank.sas
  @li mv_deletejes.sas

  @param path= The full path (on SAS Drive) where the job will be created
  @param name= The name of the job
  @param desc= The description of the job
  @param precode= Space separated list of filerefs, pointing to the code that
    needs to be attached to the beginning of the job
  @param code= Fileref(s) of the actual code to be added
  @param access_token_var= The global macro variable to contain the access token
  @param grant_type= valid values are "password" or "authorization_code"
    (unquoted). The default is authorization_code.
  @param replace= select NO to avoid replacing any existing job in that location
  @param contextname= Choose a specific context on which to run the Job.  Leave
    blank to use the default context.  From Viya 3.5 it is possible to configure
    a shared context - see
https://go.documentation.sas.com/?docsetId=calcontexts&docsetTarget=n1hjn8eobk5pyhn1wg3ja0drdl6h.htm&docsetVersion=3.5&locale=en

  @version VIYA V.03.04
  @author [Allan Bowe](https://www.linkedin.com/in/allanbowe)

**/

%macro mv_createjob(path=
    ,name=
    ,desc=Created by the mv_createjob.sas macro
    ,precode=
    ,code=ft15f001
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,replace=YES
    ,debug=0
    ,contextname=
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

/* initial validation checking */
%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)
%mp_abort(iftrue=(%mf_isblank(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mp_abort(iftrue=(%length(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mp_abort(iftrue=(%mf_isblank(&name)=1)
  ,mac=&sysmacroname
  ,msg=%str(name value must be provided)
)

options noquotelenmax;

* remove any trailing slash ;
%if "%substr(&path,%length(&path),1)" = "/" %then
  %let path=%substr(&path,1,%length(&path)-1);

/* ensure folder exists */
%put &sysmacroname: Path &path being checked / created;
%mv_createfolder(path=&path)

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* fetching folder details for provided path */
%local fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri/folders/folders/@item?path=&path";
%if &grant_type=authorization_code %then %do;
  headers "Authorization"="Bearer &&&access_token_var";
%end;
run;
%if &debug %then %do;
  data _null_;
    infile &fname1;
    input;
    putlog _infile_;
  run;
%end;
%mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)

/* path exists. Grab follow on link to check members */
%local libref1;
%let libref1=%mf_getuniquelibref();
libname &libref1 JSON fileref=&fname1;

data _null_;
  set &libref1..links;
  if rel='members' then call symputx('membercheck',quote("&base_uri"!!trim(href)),'l');
  else if rel='self' then call symputx('parentFolderUri',href,'l');
run;
data _null_;
  set &libref1..root;
  call symputx('folderid',id,'l');
run;
%local fname2;
%let fname2=%mf_getuniquefileref();
proc http method='GET'
    out=&fname2
    &oauth_bearer
    url=%unquote(%superq(membercheck));
    headers
  %if &grant_type=authorization_code %then %do;
            "Authorization"="Bearer &&&access_token_var"
  %end;
            'Accept'='application/vnd.sas.collection+json'
            'Accept-Language'='string';
%if &debug=1 %then %do;
    debug level = 3;
%end;
run;
/*data _null_;infile &fname2;input;putlog _infile_;run;*/
%mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)

%if %upcase(&replace)=YES %then %do;
  %mv_deletejes(path=&path, name=&name)
%end;
%else %do;
  /* check that job does not already exist in that folder */
  %local libref2;
  %let libref2=%mf_getuniquelibref();
  libname &libref2 JSON fileref=&fname2;
  %local exists; %let exists=0;
  data _null_;
    set &libref2..items;
    if contenttype='jobDefinition' and upcase(name)="%upcase(&name)" then
      call symputx('exists',1,'l');
  run;
  %mp_abort(iftrue=(&exists=1)
    ,mac=&sysmacroname
    ,msg=%str(Job &name already exists in &path)
  )
  libname &libref2 clear;
%end;

/* set up the body of the request to create the service */
%local fname3;
%let fname3=%mf_getuniquefileref();
data _null_;
  file &fname3 TERMSTR=' ';
  length string $32767;
  string=cats('{"version": 0,"name":"'
    ,"&name"
    ,'","type":"Compute","parameters":[{"name":"_addjesbeginendmacros"'
    ,',"type":"CHARACTER","defaultValue":"false"}');
  context=quote(cats(symget('contextname')));
  if context ne '""' then do;
    string=cats(string,',{"version": 1,"name": "_contextName","defaultValue":'
      ,context,',"type":"CHARACTER","label":"Context Name","required": false}');
  end;
  string=cats(string,'],"code":"');
  put string;
run;


/* insert the code, escaping double quotes and carriage returns */
%local x fref freflist;
%let freflist= &precode &code ;
%do x=1 %to %sysfunc(countw(&freflist));
  %let fref=%scan(&freflist,&x);
  %put &sysmacroname: adding &fref;
  data _null_;
    length filein 8 fileid 8;
    filein = fopen("&fref","I",1,"B");
    fileid = fopen("&fname3","A",1,"B");
    rec = "20"x;
    do while(fread(filein)=0);
      rc = fget(filein,rec,1);
      if rec='"' then do;  /* DOUBLE QUOTE */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'"');rc =fwrite(fileid);
      end;
      else if rec='0A'x then do; /* LF */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'n');rc =fwrite(fileid);
      end;
      else if rec='0D'x then do; /* CR */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'r');rc =fwrite(fileid);
      end;
      else if rec='09'x then do; /* TAB */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'t');rc =fwrite(fileid);
      end;
      else if rec='5C'x then do; /* BACKSLASH */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'\');rc =fwrite(fileid);
      end;
      else if rec='01'x then do; /* Unprintable */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'u');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'1');rc =fwrite(fileid);
      end;
      else if rec='07'x then do; /* Bell Char */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'u');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'7');rc =fwrite(fileid);
      end;
      else if rec='1B'x then do; /* escape char */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'u');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'1');rc =fwrite(fileid);
        rc =fput(fileid,'B');rc =fwrite(fileid);
      end;
      else do;
        rc =fput(fileid,rec);
        rc =fwrite(fileid);
      end;
    end;
    rc=fclose(filein);
    rc=fclose(fileid);
  run;
%end;

/* finish off the body of the code file loaded to JES */
data _null_;
  file &fname3 mod TERMSTR=' ';
  put '"}';
run;

/* now we can create the job!! */
%local fname4;
%let fname4=%mf_getuniquefileref();
proc http method='POST'
    in=&fname3
    out=&fname4
    &oauth_bearer
    url="&base_uri/jobDefinitions/definitions?parentFolderUri=&parentFolderUri";
    headers 'Content-Type'='application/vnd.sas.job.definition+json'
  %if &grant_type=authorization_code %then %do;
            "Authorization"="Bearer &&&access_token_var"
  %end;
            "Accept"="application/vnd.sas.job.definition+json";
%if &debug=1 %then %do;
    debug level = 3;
%end;
run;
/*data _null_;infile &fname4;input;putlog _infile_;run;*/
%mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 201)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)
/* clear refs */
filename &fname1 clear;
filename &fname2 clear;
filename &fname3 clear;
filename &fname4 clear;
libname &libref1 clear;

/* get the url so we can give a helpful log message */
%local url;
data _null_;
  if symexist('_baseurl') then do;
    url=symget('_baseurl');
    if subpad(url,length(url)-9,9)='SASStudio'
      then url=substr(url,1,length(url)-11);
    else url="&systcpiphostname";
  end;
  else url="&systcpiphostname";
  call symputx('url',url);
run;


%put &sysmacroname: Job &name successfully created in &path;
%put &sysmacroname:;
%put &sysmacroname: Check it out here:;
%put &sysmacroname:;%put;
%put    &url/SASJobExecution?_PROGRAM=&path/&name;%put;
%put &sysmacroname:;
%put &sysmacroname:;

%mend mv_createjob;
/**
  @file
  @brief Creates a JobExecution web service if it doesn't already exist
  @details
  Code is passed in as one or more filerefs.

      %* Step 1 - compile macros ;
      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %* Step 2 - Create some code and add it to a web service;
      filename ft15f001 temp;
      parmcards4;
          %webout(FETCH) %* fetch any tables sent from frontend;
          %* do some sas, any inputs are now already WORK tables;
          data example1 example2;
            set sashelp.class;
          run;
          %* send data back;
          %webout(OPEN)
          %webout(ARR,example1) * Array format, fast, suitable for large tables;
          %webout(OBJ,example2) * Object format, easier to work with ;
          %webout(CLOSE)
      ;;;;
      %mv_createwebservice(path=/Public/app/common,name=appinit)


  Notes:
    To minimise postgres requests, output json is stored in a temporary file
    and then sent to _webout in one go at the end.

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mv_createfolder.sas
  @li mf_getuniquelibref.sas
  @li mf_getuniquefileref.sas
  @li mf_getplatform.sas
  @li mf_isblank.sas
  @li mv_deletejes.sas

  @param [in] path= The full path (on SAS Drive) where the service will be
    created
  @param [in] name= The name of the service
  @param [in] desc= The description of the service
  @param [in] precode= Space separated list of filerefs, pointing to the code
    that needs to be attached to the beginning of the service
  @param [in] code= Fileref(s) of the actual code to be added
  @param [in] access_token_var= The global macro variable to contain the access
    token
  @param [in] grant_type= valid values are "password" or "authorization_code"
    (unquoted). The default is authorization_code.
  @param [in] replace=(YES) Select NO to avoid replacing any existing service in
    that location
  @param [in] adapter= the macro uses the sasjs adapter by default.  To use
    another adapter, add a (different) fileref here.
  @param [in] contextname= Choose a specific context on which to run the Job.  Leave
    blank to use the default context.  From Viya 3.5 it is possible to configure
    a shared context - see
https://go.documentation.sas.com/?docsetId=calcontexts&docsetTarget=n1hjn8eobk5pyhn1wg3ja0drdl6h.htm&docsetVersion=3.5&locale=en
  @param [in] mdebug=(0) set to 1 to enable DEBUG messages

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

**/

%macro mv_createwebservice(path=
    ,name=
    ,desc=Created by the mv_createwebservice.sas macro
    ,precode=
    ,code=ft15f001
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,replace=YES
    ,adapter=sasjs
    ,mdebug=0
    ,contextname=
    ,debug=0 /* @TODO - Deprecate */
  );
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

/* initial validation checking */
%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)
%mp_abort(iftrue=(%mf_isblank(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mp_abort(iftrue=(%length(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mp_abort(iftrue=(%mf_isblank(&name)=1)
  ,mac=&sysmacroname
  ,msg=%str(name value must be provided)
)

options noquotelenmax;

* remove any trailing slash ;
%if "%substr(&path,%length(&path),1)" = "/" %then
  %let path=%substr(&path,1,%length(&path)-1);

/* ensure folder exists */
%put &sysmacroname: Path &path being checked / created;
%mv_createfolder(path=&path)

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* fetching folder details for provided path */
%local fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri/folders/folders/@item?path=&path";
%if &grant_type=authorization_code %then %do;
  headers "Authorization"="Bearer &&&access_token_var";
%end;
run;
%if &mdebug=1 %then %do;
  data _null_;
    infile &fname1;
    input;
    putlog _infile_;
  run;
%end;
%mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)

/* path exists. Grab follow on link to check members */
%local libref1;
%let libref1=%mf_getuniquelibref();
libname &libref1 JSON fileref=&fname1;

data _null_;
  set &libref1..links;
  if rel='members' then
    call symputx('membercheck',quote("&base_uri"!!trim(href)),'l');
  else if rel='self' then call symputx('parentFolderUri',href,'l');
run;
data _null_;
  set &libref1..root;
  call symputx('folderid',id,'l');
run;
%local fname2;
%let fname2=%mf_getuniquefileref();
proc http method='GET'
    out=&fname2
    &oauth_bearer
    url=%unquote(%superq(membercheck));
    headers
  %if &grant_type=authorization_code %then %do;
            "Authorization"="Bearer &&&access_token_var"
  %end;
            'Accept'='application/vnd.sas.collection+json'
            'Accept-Language'='string';
%if &mdebug=1 %then %do;
  debug level = 3;
%end;
run;
/*data _null_;infile &fname2;input;putlog _infile_;run;*/
%mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)

%if %upcase(&replace)=YES %then %do;
  %mv_deletejes(path=&path, name=&name)
%end;
%else %do;
  /* check that job does not already exist in that folder */
  %local libref2;
  %let libref2=%mf_getuniquelibref();
  libname &libref2 JSON fileref=&fname2;
  %local exists; %let exists=0;
  data _null_;
    set &libref2..items;
    if contenttype='jobDefinition' and upcase(name)="%upcase(&name)" then
      call symputx('exists',1,'l');
  run;
  %mp_abort(iftrue=(&exists=1)
    ,mac=&sysmacroname
    ,msg=%str(Job &name already exists in &path)
  )
  libname &libref2 clear;
%end;

/* set up the body of the request to create the service */
%local fname3;
%let fname3=%mf_getuniquefileref();
data _null_;
  file &fname3 TERMSTR=' ';
  length string $32767;
  string=cats('{"version": 0,"name":"'
    ,"&name"
    ,'","type":"Compute","parameters":[{"name":"_addjesbeginendmacros"'
    ,',"type":"CHARACTER","defaultValue":"false"}');
  context=quote(cats(symget('contextname')));
  if context ne '""' then do;
    string=cats(string,',{"version": 1,"name": "_contextName","defaultValue":'
      ,context,',"type":"CHARACTER","label":"Context Name","required": false}');
  end;
  string=cats(string,'],"code":"');
  put string;
run;

/**
  * Add webout macro
  * These put statements are auto generated - to change the macro, change the
  * source (mv_webout) and run `build.py`
  */
filename &adapter temp lrecl=3000;
data _null_;
  file &adapter;
  put "/* Created on %sysfunc(datetime(),datetime19.) by &sysuserid */";
/* WEBOUT BEGIN */
  put ' ';
  put '%macro mp_jsonout(action,ds,jref=_webout,dslabel=,fmt=Y,engine=DATASTEP,dbg=0 ';
  put ')/*/STORE SOURCE*/; ';
  put '%put output location=&jref; ';
  put '%if &action=OPEN %then %do; ';
  put '  options nobomfile; ';
  put '  data _null_;file &jref encoding=''utf-8'' ; ';
  put '    put ''{"PROCESSED_DTTM" : "'' "%sysfunc(datetime(),E8601DT26.6)" ''"''; ';
  put '  run; ';
  put '%end; ';
  put '%else %if (&action=ARR or &action=OBJ) %then %do; ';
  put '  options validvarname=upcase; ';
  put '  data _null_;file &jref mod encoding=''utf-8'' ; ';
  put '    put ", ""%lowcase(%sysfunc(coalescec(&dslabel,&ds)))"":"; ';
  put ' ';
  put '  %if &engine=PROCJSON %then %do; ';
  put '    data;run;%let tempds=&syslast; ';
  put '    proc sql;drop table &tempds; ';
  put '    data &tempds /view=&tempds;set &ds; ';
  put '    %if &fmt=N %then format _numeric_ best32.;; ';
  put '    proc json out=&jref pretty ';
  put '        %if &action=ARR %then nokeys ; ';
  put '        ;export &tempds / nosastags fmtnumeric; ';
  put '    run; ';
  put '    proc sql;drop view &tempds; ';
  put '  %end; ';
  put '  %else %if &engine=DATASTEP %then %do; ';
  put '    %local cols i tempds; ';
  put '    %let cols=0; ';
  put '    %if %sysfunc(exist(&ds)) ne 1 & %sysfunc(exist(&ds,VIEW)) ne 1 %then %do; ';
  put '      %put &sysmacroname:  &ds NOT FOUND!!!; ';
  put '      %return; ';
  put '    %end; ';
  put '    %if &fmt=Y %then %do; ';
  put '      %put converting every variable to a formatted variable; ';
  put '      /* see mp_ds2fmtds.sas for source */ ';
  put '      proc contents noprint data=&ds ';
  put '        out=_data_(keep=name type length format formatl formatd varnum); ';
  put '      run; ';
  put '      proc sort; ';
  put '        by varnum; ';
  put '      run; ';
  put '      %local fmtds; ';
  put '      %let fmtds=%scan(&syslast,2,.); ';
  put '      /* prepare formats and varnames */ ';
  put '      data _null_; ';
  put '        if _n_=1 then call symputx(''nobs'',nobs,''l''); ';
  put '        set &fmtds end=last nobs=nobs; ';
  put '        name=upcase(name); ';
  put '        /* fix formats */ ';
  put '        if type=2 or type=6 then do; ';
  put '          length fmt $49.; ';
  put '          if format='''' then fmt=cats(''$'',length,''.''); ';
  put '          else if formatl=0 then fmt=cats(format,''.''); ';
  put '          else fmt=cats(format,formatl,''.''); ';
  put '          newlen=max(formatl,length); ';
  put '        end; ';
  put '        else do; ';
  put '          if format='''' then fmt=''best.''; ';
  put '          else if formatl=0 then fmt=cats(format,''.''); ';
  put '          else if formatd=0 then fmt=cats(format,formatl,''.''); ';
  put '          else fmt=cats(format,formatl,''.'',formatd); ';
  put '          /* needs to be wide, for datetimes etc */ ';
  put '          newlen=max(length,formatl,24); ';
  put '        end; ';
  put '        /* 32 char unique name */ ';
  put '        newname=''sasjs''!!substr(cats(put(md5(name),$hex32.)),1,27); ';
  put ' ';
  put '        call symputx(cats(''name'',_n_),name,''l''); ';
  put '        call symputx(cats(''newname'',_n_),newname,''l''); ';
  put '        call symputx(cats(''len'',_n_),newlen,''l''); ';
  put '        call symputx(cats(''fmt'',_n_),fmt,''l''); ';
  put '        call symputx(cats(''type'',_n_),type,''l''); ';
  put '      run; ';
  put '      data &fmtds; ';
  put '        /* rename on entry */ ';
  put '        set &ds(rename=( ';
  put '      %local i; ';
  put '      %do i=1 %to &nobs; ';
  put '        &&name&i=&&newname&i ';
  put '      %end; ';
  put '        )); ';
  put '      %do i=1 %to &nobs; ';
  put '        length &&name&i $&&len&i; ';
  put '        &&name&i=left(put(&&newname&i,&&fmt&i)); ';
  put '        drop &&newname&i; ';
  put '      %end; ';
  put '        if _error_ then call symputx(''syscc'',1012); ';
  put '      run; ';
  put '      %let ds=&fmtds; ';
  put '    %end; /* &fmt=Y */ ';
  put '    data _null_;file &jref mod encoding=''utf-8'' ; ';
  put '      put "["; call symputx(''cols'',0,''l''); ';
  put '    proc sort ';
  put '      data=sashelp.vcolumn(where=(libname=''WORK'' & memname="%upcase(&ds)")) ';
  put '      out=_data_; ';
  put '      by varnum; ';
  put ' ';
  put '    data _null_; ';
  put '      set _last_ end=last; ';
  put '      call symputx(cats(''name'',_n_),name,''l''); ';
  put '      call symputx(cats(''type'',_n_),type,''l''); ';
  put '      call symputx(cats(''len'',_n_),length,''l''); ';
  put '      if last then call symputx(''cols'',_n_,''l''); ';
  put '    run; ';
  put ' ';
  put '    proc format; /* credit yabwon for special null removal */ ';
  put '      value bart ._ - .z = null ';
  put '      other = [best.]; ';
  put ' ';
  put '    data;run; %let tempds=&syslast; /* temp table for spesh char management */ ';
  put '    proc sql; drop table &tempds; ';
  put '    data &tempds/view=&tempds; ';
  put '      attrib _all_ label=''''; ';
  put '      %do i=1 %to &cols; ';
  put '        %if &&type&i=char %then %do; ';
  put '          length &&name&i $32767; ';
  put '          format &&name&i $32767.; ';
  put '        %end; ';
  put '      %end; ';
  put '      set &ds; ';
  put '      format _numeric_ bart.; ';
  put '    %do i=1 %to &cols; ';
  put '      %if &&type&i=char %then %do; ';
  put '        &&name&i=''"''!!trim(prxchange(''s/"/\"/'',-1, ';
  put '                    prxchange(''s/''!!''0A''x!!''/\n/'',-1, ';
  put '                    prxchange(''s/''!!''0D''x!!''/\r/'',-1, ';
  put '                    prxchange(''s/''!!''09''x!!''/\t/'',-1, ';
  put '                    prxchange(''s/\\/\\\\/'',-1,&&name&i) ';
  put '        )))))!!''"''; ';
  put '      %end; ';
  put '    %end; ';
  put '    run; ';
  put '    /* write to temp loc to avoid _webout truncation ';
  put '      - https://support.sas.com/kb/49/325.html */ ';
  put '    filename _sjs temp lrecl=131068 encoding=''utf-8''; ';
  put '    data _null_; file _sjs lrecl=131068 encoding=''utf-8'' mod ; ';
  put '      set &tempds; ';
  put '      if _n_>1 then put "," @; put ';
  put '      %if &action=ARR %then "[" ; %else "{" ; ';
  put '      %do i=1 %to &cols; ';
  put '        %if &i>1 %then  "," ; ';
  put '        %if &action=OBJ %then """&&name&i"":" ; ';
  put '        &&name&i ';
  put '      %end; ';
  put '      %if &action=ARR %then "]" ; %else "}" ; ; ';
  put '    proc sql; ';
  put '    drop view &tempds; ';
  put '    /* now write the long strings to _webout 1 byte at a time */ ';
  put '    data _null_; ';
  put '      length filein 8 fileid 8; ';
  put '      filein = fopen("_sjs",''I'',1,''B''); ';
  put '      fileid = fopen("&jref",''A'',1,''B''); ';
  put '      rec = ''20''x; ';
  put '      do while(fread(filein)=0); ';
  put '        rc = fget(filein,rec,1); ';
  put '        rc = fput(fileid, rec); ';
  put '        rc =fwrite(fileid); ';
  put '      end; ';
  put '      rc = fclose(filein); ';
  put '      rc = fclose(fileid); ';
  put '    run; ';
  put '    filename _sjs clear; ';
  put '    data _null_; file &jref mod encoding=''utf-8'' ; ';
  put '      put "]"; ';
  put '    run; ';
  put '  %end; ';
  put '%end; ';
  put ' ';
  put '%else %if &action=CLOSE %then %do; ';
  put '  data _null_;file &jref encoding=''utf-8'' mod ; ';
  put '    put "}"; ';
  put '  run; ';
  put '%end; ';
  put '%mend mp_jsonout; ';
  put '%macro mv_webout(action,ds,fref=_mvwtemp,dslabel=,fmt=Y,stream=Y); ';
  put '%global _webin_file_count _webin_fileuri _debug _omittextlog _webin_name ';
  put '  sasjs_tables SYS_JES_JOB_URI; ';
  put '%if %index("&_debug",log) %then %let _debug=131; ';
  put ' ';
  put '%local i tempds; ';
  put '%let action=%upcase(&action); ';
  put ' ';
  put '%if &action=FETCH %then %do; ';
  put '  %if %upcase(&_omittextlog)=FALSE or %str(&_debug) ge 131 %then %do; ';
  put '    options mprint notes mprintnest; ';
  put '  %end; ';
  put ' ';
  put '  %if not %symexist(_webin_fileuri1) %then %do; ';
  put '    %let _webin_file_count=%eval(&_webin_file_count+0); ';
  put '    %let _webin_fileuri1=&_webin_fileuri; ';
  put '    %let _webin_name1=&_webin_name; ';
  put '  %end; ';
  put ' ';
  put '  /* if the sasjs_tables param is passed, we expect param based upload */ ';
  put '  %if %length(&sasjs_tables.XX)>2 %then %do; ';
  put '    filename _sasjs "%sysfunc(pathname(work))/sasjs.lua"; ';
  put '    data _null_; ';
  put '      file _sasjs; ';
  put '      put ''s=sas.symget("sasjs_tables")''; ';
  put '      put ''if(s:sub(1,7) == "%nrstr(")''; ';
  put '      put ''then''; ';
  put '      put '' tablist=s:sub(8,s:len()-1)''; ';
  put '      put ''else''; ';
  put '      put '' tablist=s''; ';
  put '      put ''end''; ';
  put '      put ''for i = 1,sas.countw(tablist) ''; ';
  put '      put ''do ''; ';
  put '      put ''  tab=sas.scan(tablist,i)''; ';
  put '      put ''  sasdata=""''; ';
  put '      put ''  if (sas.symexist("sasjs"..i.."data0")==0)''; ';
  put '      put ''  then''; ';
  put '      /* TODO - condense this logic */ ';
  put '      put ''    s=sas.symget("sasjs"..i.."data")''; ';
  put '      put ''    if(s:sub(1,7) == "%nrstr(")''; ';
  put '      put ''    then''; ';
  put '      put ''      sasdata=s:sub(8,s:len()-1)''; ';
  put '      put ''    else''; ';
  put '      put ''      sasdata=s''; ';
  put '      put ''    end''; ';
  put '      put ''  else''; ';
  put '      put ''    for d = 1, sas.symget("sasjs"..i.."data0")''; ';
  put '      put ''    do''; ';
  put '      put ''      s=sas.symget("sasjs"..i.."data"..d)''; ';
  put '      put ''      if(s:sub(1,7) == "%nrstr(")''; ';
  put '      put ''      then''; ';
  put '      put ''        sasdata=sasdata..s:sub(8,s:len()-1)''; ';
  put '      put ''      else''; ';
  put '      put ''        sasdata=sasdata..s''; ';
  put '      put ''      end''; ';
  put '      put ''    end''; ';
  put '      put ''  end''; ';
  put '      put ''  file = io.open(sas.pathname("work").."/"..tab..".csv", "a")''; ';
  put '      put ''  io.output(file)''; ';
  put '      put ''  io.write(sasdata)''; ';
  put '      put ''  io.close(file)''; ';
  put '      put ''end''; ';
  put '    run; ';
  put '    %inc _sasjs; ';
  put ' ';
  put '    /* now read in the data */ ';
  put '    %do i=1 %to %sysfunc(countw(&sasjs_tables)); ';
  put '      %local table; %let table=%scan(&sasjs_tables,&i); ';
  put '      data _null_; ';
  put '        infile "%sysfunc(pathname(work))/&table..csv" termstr=crlf ; ';
  put '        input; ';
  put '        if _n_=1 then call symputx(''input_statement'',_infile_); ';
  put '        list; ';
  put '      data &table; ';
  put '        infile "%sysfunc(pathname(work))/&table..csv" firstobs=2 dsd ';
  put '          termstr=crlf; ';
  put '        input &input_statement; ';
  put '      run; ';
  put '    %end; ';
  put '  %end; ';
  put '  %else %do i=1 %to &_webin_file_count; ';
  put '    /* read in any files that are sent */ ';
  put '    /* this part needs refactoring for wide files */ ';
  put '    filename indata filesrvc "&&_webin_fileuri&i" lrecl=999999; ';
  put '    data _null_; ';
  put '      infile indata termstr=crlf lrecl=32767; ';
  put '      input; ';
  put '      if _n_=1 then call symputx(''input_statement'',_infile_); ';
  put '      %if %str(&_debug) ge 131 %then %do; ';
  put '        if _n_<20 then putlog _infile_; ';
  put '        else stop; ';
  put '      %end; ';
  put '      %else %do; ';
  put '        stop; ';
  put '      %end; ';
  put '    run; ';
  put '    data &&_webin_name&i; ';
  put '      infile indata firstobs=2 dsd termstr=crlf ; ';
  put '      input &input_statement; ';
  put '    run; ';
  put '    %let sasjs_tables=&sasjs_tables &&_webin_name&i; ';
  put '  %end; ';
  put '%end; ';
  put '%else %if &action=OPEN %then %do; ';
  put '  /* setup webout */ ';
  put '  OPTIONS NOBOMFILE; ';
  put '  %if "X&SYS_JES_JOB_URI.X"="XX" %then %do; ';
  put '    filename _webout temp lrecl=999999 mod; ';
  put '  %end; ';
  put '  %else %do; ';
  put '    filename _webout filesrvc parenturi="&SYS_JES_JOB_URI" ';
  put '      name="_webout.json" lrecl=999999 mod; ';
  put '  %end; ';
  put ' ';
  put '  /* setup temp ref */ ';
  put '  %if %upcase(&fref) ne _WEBOUT %then %do; ';
  put '    filename &fref temp lrecl=999999 permission=''A::u::rwx,A::g::rw-,A::o::---'' ';
  put '      mod; ';
  put '  %end; ';
  put ' ';
  put '  /* setup json */ ';
  put '  data _null_;file &fref; ';
  put '    put ''{"START_DTTM" : "'' "%sysfunc(datetime(),datetime20.3)" ''"''; ';
  put '  run; ';
  put '%end; ';
  put '%else %if &action=ARR or &action=OBJ %then %do; ';
  put '    %mp_jsonout(&action,&ds,dslabel=&dslabel,fmt=&fmt ';
  put '      ,jref=&fref,engine=DATASTEP,dbg=%str(&_debug) ';
  put '    ) ';
  put '%end; ';
  put '%else %if &action=CLOSE %then %do; ';
  put '  %if %str(&_debug) ge 131 %then %do; ';
  put '    /* send back first 10 records of each work table for debugging */ ';
  put '    options obs=10; ';
  put '    data;run;%let tempds=%scan(&syslast,2,.); ';
  put '    ods output Members=&tempds; ';
  put '    proc datasets library=WORK memtype=data; ';
  put '    %local wtcnt;%let wtcnt=0; ';
  put '    data _null_; ';
  put '      set &tempds; ';
  put '      if not (upcase(name) =:"DATA"); /* ignore temp datasets */ ';
  put '      i+1; ';
  put '      call symputx(''wt''!!left(i),name); ';
  put '      call symputx(''wtcnt'',i); ';
  put '    data _null_; file &fref mod; put ",""WORK"":{"; ';
  put '    %do i=1 %to &wtcnt; ';
  put '      %let wt=&&wt&i; ';
  put '      proc contents noprint data=&wt ';
  put '        out=_data_ (keep=name type length format:); ';
  put '      run;%let tempds=%scan(&syslast,2,.); ';
  put '      data _null_; file &fref mod; ';
  put '        dsid=open("WORK.&wt",''is''); ';
  put '        nlobs=attrn(dsid,''NLOBS''); ';
  put '        nvars=attrn(dsid,''NVARS''); ';
  put '        rc=close(dsid); ';
  put '        if &i>1 then put '',''@; ';
  put '        put " ""&wt"" : {"; ';
  put '        put ''"nlobs":'' nlobs; ';
  put '        put '',"nvars":'' nvars; ';
  put '      %mp_jsonout(OBJ,&tempds,jref=&fref,dslabel=colattrs,engine=DATASTEP) ';
  put '      %mp_jsonout(OBJ,&wt,jref=&fref,dslabel=first10rows,engine=DATASTEP) ';
  put '      data _null_; file &fref mod;put "}"; ';
  put '    %end; ';
  put '    data _null_; file &fref mod;put "}";run; ';
  put '  %end; ';
  put ' ';
  put '  /* close off json */ ';
  put '  data _null_;file &fref mod; ';
  put '    _PROGRAM=quote(trim(resolve(symget(''_PROGRAM'')))); ';
  put '    put ",""SYSUSERID"" : ""&sysuserid"" "; ';
  put '    put ",""MF_GETUSER"" : ""%mf_getuser()"" "; ';
  put '    SYS_JES_JOB_URI=quote(trim(resolve(symget(''SYS_JES_JOB_URI'')))); ';
  put '    put '',"SYS_JES_JOB_URI" : '' SYS_JES_JOB_URI ; ';
  put '    put ",""SYSJOBID"" : ""&sysjobid"" "; ';
  put '    put ",""_DEBUG"" : ""&_debug"" "; ';
  put '    put '',"_PROGRAM" : '' _PROGRAM ; ';
  put '    put ",""SYSCC"" : ""&syscc"" "; ';
  put '    put ",""SYSERRORTEXT"" : ""&syserrortext"" "; ';
  put '    put ",""SYSHOSTNAME"" : ""&syshostname"" "; ';
  put '    put ",""SYSSCPL"" : ""&sysscpl"" "; ';
  put '    put ",""SYSSITE"" : ""&syssite"" "; ';
  put '    sysvlong=quote(trim(symget(''sysvlong''))); ';
  put '    put '',"SYSVLONG" : '' sysvlong; ';
  put '    put ",""SYSWARNINGTEXT"" : ""&syswarningtext"" "; ';
  put '    put '',"END_DTTM" : "'' "%sysfunc(datetime(),datetime20.3)" ''" ''; ';
  put '    put "}"; ';
  put ' ';
  put '  %if %upcase(&fref) ne _WEBOUT and &stream=Y %then %do; ';
  put '    data _null_; rc=fcopy("&fref","_webout");run; ';
  put '  %end; ';
  put ' ';
  put '%end; ';
  put ' ';
  put '%mend mv_webout; ';
  put ' ';
  put '%macro mf_getuser(type=META ';
  put ')/*/STORE SOURCE*/; ';
  put '  %local user metavar; ';
  put '  %if &type=OS %then %let metavar=_secureusername; ';
  put '  %else %let metavar=_metaperson; ';
  put ' ';
  put '  %if %symexist(SYS_COMPUTE_SESSION_OWNER) %then %let user=&SYS_COMPUTE_SESSION_OWNER; ';
  put '  %else %if %symexist(&metavar) %then %do; ';
  put '    %if %length(&&&metavar)=0 %then %let user=&sysuserid; ';
  put '    /* sometimes SAS will add @domain extension - remove for consistency */ ';
  put '    %else %let user=%scan(&&&metavar,1,@); ';
  put '  %end; ';
  put '  %else %let user=&sysuserid; ';
  put ' ';
  put '  %quote(&user) ';
  put ' ';
  put '%mend mf_getuser; ';
/* WEBOUT END */
  put '/* if calling viya service with _job param, _program will conflict */';
  put '/* so it is provided by SASjs instead as __program */';
  put '%global __program _program;';
  put '%let _program=%sysfunc(coalescec(&__program,&_program));';
  put ' ';
  put '%macro webout(action,ds,dslabel=,fmt=);';
  put '  %mv_webout(&action,ds=&ds,dslabel=&dslabel,fmt=&fmt)';
  put '%mend;';
run;

/* insert the code, escaping double quotes and carriage returns */
%&dbg.put &sysmacroname: Creating final input file;
%local x fref freflist;
%let freflist= &adapter &precode &code ;
%do x=1 %to %sysfunc(countw(&freflist));
  %let fref=%scan(&freflist,&x);
  %&dbg.put &sysmacroname: adding &fref fileref;
  data _null_;
    length filein 8 fileid 8;
    filein = fopen("&fref","I",1,"B");
    fileid = fopen("&fname3","A",1,"B");
    rec = "20"x;
    do while(fread(filein)=0);
      rc = fget(filein,rec,1);
      if rec='"' then do;  /* DOUBLE QUOTE */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'"');rc =fwrite(fileid);
      end;
      else if rec='0A'x then do; /* LF */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'n');rc =fwrite(fileid);
      end;
      else if rec='0D'x then do; /* CR */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'r');rc =fwrite(fileid);
      end;
      else if rec='09'x then do; /* TAB */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'t');rc =fwrite(fileid);
      end;
      else if rec='5C'x then do; /* BACKSLASH */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'\');rc =fwrite(fileid);
      end;
      else if rec='01'x then do; /* Unprintable */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'u');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'1');rc =fwrite(fileid);
      end;
      else if rec='07'x then do; /* Bell Char */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'u');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'7');rc =fwrite(fileid);
      end;
      else if rec='1B'x then do; /* escape char */
        rc =fput(fileid,'\');rc =fwrite(fileid);
        rc =fput(fileid,'u');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'0');rc =fwrite(fileid);
        rc =fput(fileid,'1');rc =fwrite(fileid);
        rc =fput(fileid,'B');rc =fwrite(fileid);
      end;
      else do;
        rc =fput(fileid,rec);
        rc =fwrite(fileid);
      end;
    end;
    rc=fclose(filein);
    rc=fclose(fileid);
  run;
%end;

/* finish off the body of the code file loaded to JES */
data _null_;
  file &fname3 mod TERMSTR=' ';
  put '"}';
run;

%if &mdebug=1 and &SYS_PROCHTTP_STATUS_CODE ne 201 %then %do;
  %put &sysmacroname: input about to be POSTed;
  data _null_;infile &fname3;input;putlog _infile_;run;
%end;

%&dbg.put &sysmacroname: Creating the actual service!;
%local fname4;
%let fname4=%mf_getuniquefileref();
proc http method='POST'
    in=&fname3
    out=&fname4
    &oauth_bearer
    url="&base_uri/jobDefinitions/definitions?parentFolderUri=&parentFolderUri";
    headers 'Content-Type'='application/vnd.sas.job.definition+json'
  %if &grant_type=authorization_code %then %do;
            "Authorization"="Bearer &&&access_token_var"
  %end;
            "Accept"="application/vnd.sas.job.definition+json";
%if &mdebug=1 %then %do;
    debug level = 3;
%end;
run;
%if &mdebug=1 and &SYS_PROCHTTP_STATUS_CODE ne 201 %then %do;
  %put &sysmacroname: output from POSTing job definition;
  data _null_;infile &fname4;input;putlog _infile_;run;
%end;
%mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 201)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)

/* get the url so we can give a helpful log message */
%local url;
data _null_;
  if symexist('_baseurl') then do;
    url=symget('_baseurl');
    if subpad(url,length(url)-9,9)='SASStudio'
      then url=substr(url,1,length(url)-11);
    else url="&systcpiphostname";
  end;
  else url="&systcpiphostname";
  call symputx('url',url);
run;

%if &mdebug=1 %then %do;
  %put &sysmacroname exit vars:;
  %put _local_;
%end;
%else %do;
  /* clear refs */
  filename &fname1 clear;
  filename &fname2 clear;
  filename &fname3 clear;
  filename &fname4 clear;
  filename &adapter clear;
  libname &libref1 clear;
%end;

%put &sysmacroname: Job &name successfully created in &path;
%put &sysmacroname:;
%put &sysmacroname: Check it out here:;
%put &sysmacroname:;%put;
%put    &url/SASJobExecution?_PROGRAM=&path/&name;%put;
%put &sysmacroname:;
%put &sysmacroname:;

%mend mv_createwebservice;
/**
  @file mv_deletefoldermember.sas
  @brief Deletes an item in a Viya folder
  @details If not executed in Studio 5+  will expect oauth token in a global
  macro variable (default ACCESS_TOKEN).

      filename mc url "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %mv_createwebservice(path=/Public/test, name=blah)
      %mv_deletejes(path=/Public/test, name=blah)


  @param path= The full path of the folder containing the item to be deleted
  @param name= The name of the item to be deleted
  @param contenttype= The contenttype of the item, eg: file, jobDefinition
  @param access_token_var= The global macro variable to contain the access token
  @param grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is "detect" (which will run in Studio 5+ without a token).


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_isblank.sas

**/

%macro mv_deletefoldermember(path=
    ,name=
    ,contenttype=
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)
%mp_abort(iftrue=(%mf_isblank(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mp_abort(iftrue=(%mf_isblank(&name)=1)
  ,mac=&sysmacroname
  ,msg=%str(name value must be provided)
)
%mp_abort(iftrue=(%length(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)

options noquotelenmax;

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

%put &sysmacroname: fetching details for &path ;
%local fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri/folders/folders/@item?path=&path";
%if &grant_type=authorization_code %then %do;
  headers "Authorization"="Bearer &&&access_token_var";
%end;
run;
%if &SYS_PROCHTTP_STATUS_CODE=404 %then %do;
  %put &sysmacroname: Folder &path NOT FOUND - nothing to delete!;
  %return;
%end;
%else %if &SYS_PROCHTTP_STATUS_CODE ne 200 %then %do;
  /*data _null_;infile &fname1;input;putlog _infile_;run;*/
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;

%put &sysmacroname: grab the follow on link ;
%local libref1;
%let libref1=%mf_getuniquelibref();
libname &libref1 JSON fileref=&fname1;
data _null_;
  set &libref1..links;
  if rel='members' then call symputx('mref',quote("&base_uri"!!trim(href)),'l');
run;

/* get the children */
%local fname1a;
%let fname1a=%mf_getuniquefileref();
proc http method='GET' out=&fname1a &oauth_bearer
  url=%unquote(%superq(mref));
%if &grant_type=authorization_code %then %do;
  headers "Authorization"="Bearer &&&access_token_var";
%end;
run;
%put &=SYS_PROCHTTP_STATUS_CODE;
%local libref1a;
%let libref1a=%mf_getuniquelibref();
libname &libref1a JSON fileref=&fname1a;
%local uri found;
%let found=0;
%put Getting object uri from &libref1a..items;
data _null_;
  set &libref1a..items;
  if contenttype="&contenttype" and upcase(name)="%upcase(&name)" then do;
    call symputx('uri',uri,'l');
    call symputx('found',1,'l');
  end;
run;
%if &found=0 %then %do;
  %put NOTE:;%put NOTE- &sysmacroname: &path/&name NOT FOUND;%put NOTE- ;
  %return;
%end;
proc http method="DELETE" url="&base_uri&uri" &oauth_bearer;
  headers
%if &grant_type=authorization_code %then %do;
      "Authorization"="Bearer &&&access_token_var"
%end;
      "Accept"="*/*";/**/
run;
%if &SYS_PROCHTTP_STATUS_CODE ne 204 %then %do;
  data _null_; infile &fname2; input; putlog _infile_;run;
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;
%else %put &sysmacroname: &path/&name(&contenttype) successfully deleted;

/* clear refs */
filename &fname1 clear;
libname &libref1 clear;
filename &fname1a clear;
libname &libref1a clear;

%mend mv_deletefoldermember;/**
  @file
  @brief Deletes a Viya Job, if it exists
  @details If not executed in Studio 5+  will expect oauth token in a global
  macro variable (default ACCESS_TOKEN).

      filename mc url "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %mv_createwebservice(path=/Public/test, name=blah)
      %mv_deletejes(path=/Public/test, name=blah)


  @param path= The full path of the folder containing the Job Execution Service
  @param name= The name of the Job Execution Service to be deleted
  @param access_token_var= The global macro variable to contain the access token
  @param grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is "detect" (which will run in Studio 5+ without a token).


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_isblank.sas

**/

%macro mv_deletejes(path=
    ,name=
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)
%mp_abort(iftrue=(%mf_isblank(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mp_abort(iftrue=(%mf_isblank(&name)=1)
  ,mac=&sysmacroname
  ,msg=%str(name value must be provided)
)
%mp_abort(iftrue=(%length(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)

options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

%put &sysmacroname: fetching details for &path ;
%local fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri/folders/folders/@item?path=&path";
%if &grant_type=authorization_code %then %do;
  headers "Authorization"="Bearer &&&access_token_var";
%end;
run;
%if &SYS_PROCHTTP_STATUS_CODE=404 %then %do;
  %put &sysmacroname: Folder &path NOT FOUND - nothing to delete!;
  %return;
%end;
%else %if &SYS_PROCHTTP_STATUS_CODE ne 200 %then %do;
  /*data _null_;infile &fname1;input;putlog _infile_;run;*/
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;

%put &sysmacroname: grab the follow on link ;
%local libref1;
%let libref1=%mf_getuniquelibref();
libname &libref1 JSON fileref=&fname1;
data _null_;
  set &libref1..links;
  if rel='members' then call symputx('mref',quote("&base_uri"!!trim(href)),'l');
run;

/* get the children */
%local fname1a;
%let fname1a=%mf_getuniquefileref();
proc http method='GET' out=&fname1a &oauth_bearer
  url=%unquote(%superq(mref));
%if &grant_type=authorization_code %then %do;
  headers "Authorization"="Bearer &&&access_token_var";
%end;
run;
%put &=SYS_PROCHTTP_STATUS_CODE;
%local libref1a;
%let libref1a=%mf_getuniquelibref();
libname &libref1a JSON fileref=&fname1a;
%local uri found;
%let found=0;
%put Getting object uri from &libref1a..items;
data _null_;
  set &libref1a..items;
  if contenttype='jobDefinition' and upcase(name)="%upcase(&name)" then do;
    call symputx('uri',cats("&base_uri",uri),'l');
    call symputx('found',1,'l');
  end;
run;
%if &found=0 %then %do;
  %put NOTE:;%put NOTE- &sysmacroname: &path/&name NOT FOUND;%put NOTE- ;
  %return;
%end;
proc http method="DELETE" url="&uri" &oauth_bearer;
  headers
%if &grant_type=authorization_code %then %do;
      "Authorization"="Bearer &&&access_token_var"
%end;
      "Accept"="*/*";/**/
run;
%if &SYS_PROCHTTP_STATUS_CODE ne 204 %then %do;
  data _null_; infile &fname2; input; putlog _infile_;run;
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;
%else %put &sysmacroname: &path/&name successfully deleted;

/* clear refs */
filename &fname1 clear;
libname &libref1 clear;
filename &fname1a clear;
libname &libref1a clear;

%mend mv_deletejes;/**
  @file mv_deleteviyafolder.sas
  @brief Creates a viya folder if that folder does not already exist
  @details If not running in Studo 5 +, will expect an oauth token in a global
  macro variable (default ACCESS_TOKEN).

      %mv_createfolder(path=/Public/test/blah)
      %mv_deleteviyafolder(path=/Public/test)


  @param path= The full path of the folder to be deleted
  @param access_token_var= The global macro variable to contain the access token
  @param grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is authorization_code.


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_isblank.sas

**/

%macro mv_deleteviyafolder(path=
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)
%mp_abort(iftrue=(%mf_isblank(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)
%mp_abort(iftrue=(%length(&path)=1)
  ,mac=&sysmacroname
  ,msg=%str(path value must be provided)
)

options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

%put &sysmacroname: fetching details for &path ;
%local fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri/folders/folders/@item?path=&path";
  %if &grant_type=authorization_code %then %do;
    headers "Authorization"="Bearer &&&access_token_var";
  %end;
run;
%if &SYS_PROCHTTP_STATUS_CODE=404 %then %do;
  %put &sysmacroname: Folder &path NOT FOUND - nothing to delete!;
  %return;
%end;
%else %if &SYS_PROCHTTP_STATUS_CODE ne 200 %then %do;
  /*data _null_;infile &fname1;input;putlog _infile_;run;*/
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;

%put &sysmacroname: grab the follow on link ;
%local libref1;
%let libref1=%mf_getuniquelibref();
libname &libref1 JSON fileref=&fname1;
data _null_;
  set &libref1..links;
  if rel='deleteRecursively' then
    call symputx('href',quote("&base_uri"!!trim(href)),'l');
  else if rel='members' then
    call symputx('mref',quote(cats("&base_uri",href,'?recursive=true')),'l');
run;

/* before we can delete the folder, we need to delete the children */
%local fname1a;
%let fname1a=%mf_getuniquefileref();
proc http method='GET' out=&fname1a &oauth_bearer
  url=%unquote(%superq(mref));
%if &grant_type=authorization_code %then %do;
  headers "Authorization"="Bearer &&&access_token_var";
%end;
run;
%put &=SYS_PROCHTTP_STATUS_CODE;
%local libref1a;
%let libref1a=%mf_getuniquelibref();
libname &libref1a JSON fileref=&fname1a;

data _null_;
  set &libref1a..items_links;
  if href=:'/folders/folders' then return;
  if rel='deleteResource' then
    call execute('proc http method="DELETE" url='!!quote("&base_uri"!!trim(href))
    !!'; headers "Authorization"="Bearer &&&access_token_var" '
    !!' "Accept"="*/*";run; /**/');
run;

%put &sysmacroname: perform the delete operation ;
%local fname2;
%let fname2=%mf_getuniquefileref();
proc http method='DELETE' out=&fname2 &oauth_bearer
    url=%unquote(%superq(href));
    headers
  %if &grant_type=authorization_code %then %do;
            "Authorization"="Bearer &&&access_token_var"
  %end;
            'Accept'='*/*'; /**/
run;
%if &SYS_PROCHTTP_STATUS_CODE ne 204 %then %do;
  data _null_; infile &fname2; input; putlog _infile_;run;
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;
%else %put &sysmacroname: &path successfully deleted;

/* clear refs */
filename &fname1 clear;
filename &fname2 clear;
libname &libref1 clear;

%mend mv_deleteviyafolder;/**
  @file mv_getaccesstoken.sas
  @brief deprecated - replaced by mv_tokenrefresh.sas

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mv_tokenrefresh.sas

**/

%macro mv_getaccesstoken(client_id=someclient
    ,client_secret=somesecret
    ,grant_type=authorization_code
    ,code=
    ,user=
    ,pass=
    ,access_token_var=ACCESS_TOKEN
    ,refresh_token_var=REFRESH_TOKEN
  );

%mv_tokenrefresh(client_id=&client_id
  ,client_secret=&client_secret
  ,grant_type=&grant_type
  ,user=&user
  ,pass=&pass
  ,access_token_var=&access_token_var
  ,refresh_token_var=&refresh_token_var
)

%mend mv_getaccesstoken;/**
  @file
  @brief deprecated - replaced by mv_registerclient.sas

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mv_registerclient.sas

**/

%macro mv_getapptoken(client_id=someclient
    ,client_secret=somesecret
    ,grant_type=authorization_code
  );

%mv_registerclient(client_id=&client_id
  ,client_secret=&client_secret
  ,grant_type=&grant_type
)

%mend mv_getapptoken;/**
  @file mv_getclients.sas
  @brief Get a list of Viya Clients
  @details First, be sure you have an access token (which requires an app token).

  Using the macros here:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  An administrator needs to set you up with an access code:

      %mv_registerclient(outds=client)

  Navigate to the url from the log (opting in to the groups) and paste the
  access code below:

      %mv_tokenauth(inds=client,code=wKDZYTEPK6)

  Now we can run the macro!

      %mv_getclients()

  @param access_token_var= The global macro variable to contain the access token
  @param grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is authorization_code.
  @param outds= The library.dataset to be created that contains the list of groups


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_loc.sas

**/

%macro mv_getclients(outds=work.mv_getclients
)/*/STORE SOURCE*/;

options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* first, get consul token needed to get client id / secret */
data _null_;
  infile "%mf_loc(VIYACONFIG)/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token";
  input token:$64.;
  call symputx('consul_token',token);
run;

/* request the client details */
%local fname1;
%let fname1=%mf_getuniquefileref();
proc http method='POST' out=&fname1
    url="&base_uri/SASLogon/oauth/clients/consul?callback=false%str(&)serviceId=app";
    headers "X-Consul-Token"="&consul_token";
run;

%local libref1;
%let libref1=%mf_getuniquelibref();
libname &libref1 JSON fileref=&fname1;

/* extract the token */
data _null_;
  set &libref1..root;
  call symputx('access_token',access_token,'l');
run;

/* fetching folder details for provided path */
%local fname2;
%let fname2=%mf_getuniquefileref();
%let libref2=%mf_getuniquelibref();

proc http method='GET' out=&fname2 oauth_bearer=sas_services
  url="&base_uri/SASLogon/oauth/clients";
  headers "Accept"="application/json";
run;
/*data _null_;infile &fname1;input;putlog _infile_;run;*/
%mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)
libname &libref2 JSON fileref=&fname1;

data &outds;
  set &libref2..items;
run;



/* clear refs
filename &fname1 clear;
libname &libref1 clear;
*/
%mend mv_getclients;/**
  @file
  @brief Gets a list of folder members (and ids) for a given root
  @details Returns all members for a particular Viya folder.  Works at both root
  level and below, and results are created in an output dataset.

        %mv_getfoldermembers(root=/Public, outds=work.mymembers)


  @param [in] root= (/) The path for which to return the list of folders
  @param [out] outds= (work.mv_getfolders) The output dataset to create. Format:
  |ordinal_root|ordinal_items|creationTimeStamp| modifiedTimeStamp|createdBy|modifiedBy|id| uri|added| type|name|description|
  |---|---|---|---|---|---|---|---|---|---|---|---|
  |1|1|2021-05-25T11:15:04.204Z|2021-05-25T11:15:04.204Z|allbow|allbow|4f1e3945-9655-462b-90f2-c31534b3ca47|/folders/folders/ed701ff3-77e8-468d-a4f5-8c43dec0fd9e|2021-05-25T11:15:04.212Z|child|my_folder_name|My folder Description|

  @param [in] access_token_var= (ACCESS_TOKEN) The global macro variable to
    contain the access token
  @param [in] grant_type= (sas_services) Valid values are:
    @li password
    @li authorization_code
    @li detect
    @li sas_services

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_isblank.sas

  <h4> Related Macros </h4>
  @li mv_createfolder.sas
  @li mv_deletefoldermember.sas
  @li mv_deleteviyafolder.sas
  @li mv_getfoldermembers.test.sas

**/

%macro mv_getfoldermembers(root=/
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,outds=mv_getfolders
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%if %mf_isblank(&root)=1 %then %let root=/;

options noquotelenmax;

/* request the client details */
%local fname1 libref1;
%let fname1=%mf_getuniquefileref();
%let libref1=%mf_getuniquelibref();

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

%if "&root"="/" %then %do;
  /* if root just list root folders */
  proc http method='GET' out=&fname1 &oauth_bearer
      url="&base_uri/folders/rootFolders?limit=1000";
  %if &grant_type=authorization_code %then %do;
      headers "Authorization"="Bearer &&&access_token_var";
  %end;
  run;
  libname &libref1 JSON fileref=&fname1;
  data &outds;
    set &libref1..items;
  run;
%end;
%else %do;
  /* first get parent folder id */
  proc http method='GET' out=&fname1 &oauth_bearer
      url="&base_uri/folders/folders/@item?path=&root";
  %if &grant_type=authorization_code %then %do;
      headers "Authorization"="Bearer &&&access_token_var";
  %end;
  run;
  /*data _null_;infile &fname1;input;putlog _infile_;run;*/
  libname &libref1 JSON fileref=&fname1;
  /* now get the followon link to list members */
  %local href cnt;
  %let cnt=0;
  data _null_;
    length rel href $512;
    call missing(rel,href);
    set &libref1..links;
    if rel='members' then do;
      url=cats("'","&base_uri",href,"?limit=10000'");
      call symputx('href',url,'l');
      call symputx('cnt',1,'l');
    end;
  run;
  %if &cnt=0 %then %do;
    %put NOTE:;%put NOTE-  No members found in &root!!;%put NOTE-;
    %return;
  %end;
  %local fname2 libref2;
  %let fname2=%mf_getuniquefileref();
  %let libref2=%mf_getuniquelibref();
  proc http method='GET' out=&fname2 &oauth_bearer
      url=%unquote(%superq(href));
  %if &grant_type=authorization_code %then %do;
      headers "Authorization"="Bearer &&&access_token_var";
  %end;
  run;
  libname &libref2 JSON fileref=&fname2;
  data &outds;
    length id $36 name $128 uri $64 type $32 description $256;
    if _n_=1 then call missing (of _all_);
    set &libref2..items;
  run;
  filename &fname2 clear;
  libname &libref2 clear;
%end;


/* clear refs */
filename &fname1 clear;
libname &libref1 clear;

%mend mv_getfoldermembers;/**
  @file mv_getgroupmembers.sas
  @brief Creates a dataset with a list of group members
  @details First, be sure you have an access token (which requires an app token).

  Using the macros here:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  Now we can run the macro!

      %mv_getgroupmembers(All Users)

  outputs:

      ordinal_root num,
      ordinal_items num,
      version num,
      id char(43),
      name char(43),
      providerId char(5),
      implicit num

  @param access_token_var= The global macro variable to contain the access token
  @param grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is authorization_code.
  @param outds= The library.dataset to be created that contains the list of groups


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas

**/

%macro mv_getgroupmembers(group
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,outds=work.viyagroupmembers
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

options noquotelenmax;

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* fetching folder details for provided path */
%local fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri/identities/groups/&group/members?limit=10000";
  headers
  %if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
  %end;
          "Accept"="application/json";
run;
/*data _null_;infile &fname1;input;putlog _infile_;run;*/
%if &SYS_PROCHTTP_STATUS_CODE=404 %then %do;
  %put NOTE:  Group &group not found!!;
  data &outds;
    length id name $43;
    call missing(of _all_);
  run;
%end;
%else %do;
  %mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
    ,mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
  %let libref1=%mf_getuniquelibref();
  libname &libref1 JSON fileref=&fname1;
  data &outds;
    length id name $43;
    set &libref1..items;
  run;
  libname &libref1 clear;
%end;

/* clear refs */
filename &fname1 clear;

%mend mv_getgroupmembers;/**
  @file mv_getgroups.sas
  @brief Creates a dataset with a list of viya groups
  @details First, load the macros:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  Next, execute:

      %mv_getgroups(outds=work.groups)

  @param [in] access_token_var= The global macro variable to contain the access token
  @param [in] grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is authorization_code.
  @param [out] outds= The library.dataset to be created that contains the list of groups


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas

**/

%macro mv_getgroups(access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,outds=work.viyagroups
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* fetching folder details for provided path */
%local fname1;
%let fname1=%mf_getuniquefileref();
%let libref1=%mf_getuniquelibref();

proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri/identities/groups?limit=10000";
  headers
  %if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
  %end;
          "Accept"="application/json";
run;
/*data _null_;infile &fname1;input;putlog _infile_;run;*/
%mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)
libname &libref1 JSON fileref=&fname1;

data &outds;
  set &libref1..items;
run;



/* clear refs */
filename &fname1 clear;
libname &libref1 clear;

%mend mv_getgroups;/**
  @file
  @brief Extract the source code from a SAS Viya Job
  @details Extracts the SAS code from a Job into a fileref or physical file.
  Example:

      %mv_getjobcode(
        path=/Public/jobs
        ,name=some_job
        ,outfile=/tmp/some_job.sas
      )

  @param [in] access_token_var= The global macro variable to contain the access
    token
  @param [in] grant_type= valid values:
    @li password
    @liauthorization_code
    @li detect - will check if access_token exists, if not will use sas_services
      if a SASStudioV session else authorization_code.  Default option.
    @li  sas_services - will use oauth_bearer=sas_services
  @param [in] path= The SAS Drive path of the job
  @param [in] name= The name of the job
  @param [in] mdebug=(0) set to 1 to enable DEBUG messages
  @param [out] outref=(0) A fileref to which to write the source code (will be
    created with a TEMP engine)
  @param [out] outfile=(0) A file to which to write the source code

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mv_getfoldermembers.sas
  @li ml_json.sas

**/

%macro mv_getjobcode(outref=0,outfile=0
    ,name=0,path=0
    ,contextName=SAS Job Execution compute context
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,mdebug=0
  );
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;
%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)
%mp_abort(iftrue=("&path"="0")
  ,mac=&sysmacroname
  ,msg=%str(Job Path not provided)
)
%mp_abort(iftrue=("&name"="0")
  ,mac=&sysmacroname
  ,msg=%str(Job Name not provided)
)
%mp_abort(iftrue=("&outfile"="0" and "&outref"="0")
  ,mac=&sysmacroname
  ,msg=%str(Output destination (file or fileref) must be provided)
)
options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);
data;run;
%local foldermembers;
%let foldermembers=&syslast;
%mv_getfoldermembers(root=&path
    ,access_token_var=&access_token_var
    ,grant_type=&grant_type
    ,outds=&foldermembers
)
%local joburi;
%let joburi=0;
data _null_;
  length name uri $512;
  call missing(name,uri);
  set &foldermembers;
  if name="&name" and uri=:'/jobDefinitions/definitions'
    then call symputx('joburi',uri);
run;
%mp_abort(iftrue=("&joburi"="0")
  ,mac=&sysmacroname
  ,msg=%str(Job &path/&name not found)
)

/* prepare request*/
%local  fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri&joburi";
  headers "Accept"="application/vnd.sas.job.definition+json"
  %if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
  %end;
  ;
run;
%if &SYS_PROCHTTP_STATUS_CODE ne 200 and &SYS_PROCHTTP_STATUS_CODE ne 201 %then
%do;
  data _null_;infile &fname1;input;putlog _infile_;run;
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;
%local  fname2 fname3 fpath1 fpath2 fpath3;
%let fname2=%mf_getuniquefileref();
%let fname3=%mf_getuniquefileref();
%let fpath1=%sysfunc(pathname(&fname1));
%let fpath2=%sysfunc(pathname(&fname2));
%let fpath3=%sysfunc(pathname(&fname3));

/* compile the lua JSON module */
%ml_json()
/* read using LUA - this allows the code to be of any length */
data _null_;
  file "&fpath3..lua";
  put '
    infile = io.open (sas.symget("fpath1"), "r")
    outfile = io.open (sas.symget("fpath2"), "w")
    io.input(infile)
    local resp=json.decode(io.read())
    local job=resp["code"]
    outfile:write(job)
    io.close(infile)
    io.close(outfile)
  ';
run;
%inc "&fpath3..lua";
/* export to desired destination */
%if "&outref"="0" %then %do;
  data _null_;
    file "&outfile" lrecl=32767;
%end;
%else %do;
  filename &outref temp;
  data _null_;
    file &outref;
%end;
  infile &fname2;
  input;
  put _infile_;
  &dbg. putlog _infile_;
run;

%if &mdebug=1 %then %do;
  %put &sysmacroname exit vars:;
  %put _local_;
%end;
%else %do;
  /* clear refs */
  filename &fname1 clear;
  filename &fname2 clear;
  filename &fname3 clear;
%end;

%mend mv_getjobcode;
/**
  @file
  @brief Extract the log from a completed SAS Viya Job
  @details Extracts log from a Viya job and writes it out to a fileref.

  To query the job, you need the URI.  Sample code for achieving this
  is provided below.

  ## Example

      %* First, compile the macros;
      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %* Next, create a job (in this case, a web service);
      filename ft15f001 temp;
      parmcards4;
        data ;
          rand=ranuni(0)*1000;
          do x=1 to rand;
            y=rand*4;
            output;
          end;
        run;
        proc sort data=&syslast
          by descending y;
        run;
      ;;;;
      %mv_createwebservice(path=/Public/temp,name=demo)

      %* Execute it;
      %mv_jobexecute(path=/Public/temp
        ,name=demo
        ,outds=work.info
      )

      %* Wait for it to finish;
      data work.info;
        set work.info;
        where method='GET' and rel='state';
      run;
      %mv_jobwaitfor(ALL,inds=work.info,outds=work.jobstates)

      %* and grab the uri;
      data _null_;
        set work.jobstates;
        call symputx('uri',uri);
      run;

      %* Finally, fetch the log;
      %mv_getjoblog(uri=&uri,outref=mylog)

  This macro is used by the mv_jobwaitfor.sas macro, which is generally a more
  convenient way to wait for the job to finish before fetching the log.

  If the remote session calls `endsas` then it is not possible to get the log
  from the provided uri, and so the log from the parent session is fetched
  instead.  This happens for a 400 response, eg below:

      ErrorResponse[version=2,status=400,err=5113,id=,message=The session
      requested is currently in a failed or stopped state.,detail=[path:
      /compute/sessions/LONGURI-ses0006/jobs/LONGURI/log/content, traceId: 63
      51aa617d01fd2b],remediation=Correct the errors in the session request,
      and create a new session.,targetUri=<null>,errors=[],links=[]]

  @param [in] access_token_var= The global macro variable to contain the access
    token
  @param [in] mdebug= (0) Set to 1 to enable DEBUG messages
  @param [in] grant_type= valid values:
    @li password
    @li authorization_code
    @li detect - will check if access_token exists, if not will use sas_services
      if a SASStudioV session else authorization_code.  Default option.
    @li sas_services - will use oauth_bearer=sas_services.
  @param [in] uri= The uri of the running job for which to fetch the status,
    in the format `/jobExecution/jobs/$UUID` (unquoted).
  @param [out] outref= The output fileref to which to APPEND the log (is always
  appended).


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_existfileref.sas
  @li ml_json.sas

**/

%macro mv_getjoblog(uri=0,outref=0
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,mdebug=0
  );
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

/* validation in datastep for better character safety */
%local errmsg errflg;
data _null_;
  uri=symget('uri');
  if length(uri)<12 then do;
    call symputx('errflg',1);
    call symputx('errmsg',"URI is invalid (too short) - '&uri'",'l');
  end;
  if scan(uri,-1)='state' or scan(uri,1) ne 'jobExecution' then do;
    call symputx('errflg',1);
    call symputx('errmsg',
      "URI should be in format /jobExecution/jobs/$$$$UUID$$$$"
      !!" but is actually like:"!!uri,'l');
  end;
run;

%mp_abort(iftrue=(&errflg=1)
  ,mac=&sysmacroname
  ,msg=%str(&errmsg)
)

%mp_abort(iftrue=(&outref=0)
  ,mac=&sysmacroname
  ,msg=%str(Output fileref should be provided)
)

%if %mf_existfileref(&outref) ne 1 %then %do;
  filename &outref temp;
%end;

options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* prepare request*/
%local  fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri&uri";
  headers
  %if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
  %end;
  ;
run;
%if &mdebug=1 %then %do;
  %put &sysmacroname: fetching log loc from &uri;
  data _null_;infile &fname1;input;putlog _infile_;run;
%end;
%if &SYS_PROCHTTP_STATUS_CODE ne 200 and &SYS_PROCHTTP_STATUS_CODE ne 201 %then
%do;
  data _null_;infile &fname1;input;putlog _infile_;run;
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;
%local  fname2 fname3 fpath1 fpath2 fpath3;
%let fname2=%mf_getuniquefileref();
%let fname3=%mf_getuniquefileref();
%let fpath1=%sysfunc(pathname(&fname1));
%let fpath2=%sysfunc(pathname(&fname2));
%let fpath3=%sysfunc(pathname(&fname3));

/* compile the lua JSON module */
%ml_json()
/* read using LUA - this allows the code to be of any length */
data _null_;
  file "&fpath3..lua";
  put '
    infile = io.open (sas.symget("fpath1"), "r")
    outfile = io.open (sas.symget("fpath2"), "w")
    io.input(infile)
    local resp=json.decode(io.read())
    local logloc=resp["logLocation"]
    outfile:write(logloc)
    io.close(infile)
    io.close(outfile)
  ';
run;
%inc "&fpath3..lua";
/* get log path*/
%let errflg=1;
%let errmsg=No entry in &fname2 fileref;
data _null_;
  infile &fname2;
  input;
  uri=cats(_infile_);
  if length(uri)<12 then do;
    call symputx('errflg',1);
    call symputx('errmsg',"URI is invalid (too short) - '&uri'",'l');
  end;
  else if (scan(uri,1,'/') ne 'compute' or scan(uri,2,'/') ne 'sessions')
    and (scan(uri,1,'/') ne 'files' or scan(uri,2,'/') ne 'files')
  then do;
    call symputx('errflg',1);
    call symputx('errmsg',
      "URI should be in format /compute/sessions/$$$$UUID$$$$/jobs/$$$$UUID$$$$"
      !!" or /files/files/$$$$UUID$$$$"
      !!" but is actually like:"!!uri,'l');
  end;
  else do;
    call symputx('errflg',0,'l');
    call symputx('logloc',uri,'l');
  end;
run;

%mp_abort(iftrue=(%str(&errflg)=1)
  ,mac=&sysmacroname
  ,msg=%str(&errmsg)
)

/* we have a log uri - now fetch the log */
%&dbg.put &sysmacroname: querying &base_uri&logloc/content;
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri&logloc/content?limit=10000";
  headers
  %if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
  %end;
  ;
run;

%if &mdebug=1 %then %do;
  %put &sysmacroname: fetching log content from &base_uri&logloc/content;
  data _null_;infile &fname1;input;putlog _infile_;run;
%end;

%if &SYS_PROCHTTP_STATUS_CODE=400 %then %do;
  /* fetch log from parent session */
  %let logloc=%substr(&logloc,1,%index(&logloc,%str(/jobs/))-1);
  %&dbg.put &sysmacroname: Now querying &base_uri&logloc/log/content;
  proc http method='GET' out=&fname1 &oauth_bearer
    url="&base_uri&logloc/log/content?limit=10000";
    headers
    %if &grant_type=authorization_code %then %do;
            "Authorization"="Bearer &&&access_token_var"
    %end;
    ;
  run;
  %if &mdebug=1 %then %do;
    %put &sysmacroname: fetching log content from &base_uri&logloc/log/content;
    data _null_;infile &fname1;input;putlog _infile_;run;
  %end;
%end;

%if &SYS_PROCHTTP_STATUS_CODE ne 200 and &SYS_PROCHTTP_STATUS_CODE ne 201
%then %do;
  %if &mdebug ne 1 %then %do; /* have already output above */
    data _null_;infile &fname1;input;putlog _infile_;run;
  %end;
  %mp_abort(mac=&sysmacroname
    ,msg=%str(logfetch: &SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;
data _null_;
  file "&fpath3..lua";
  put '
    infile = io.open (sas.symget("fpath1"), "r")
    outfile = io.open (sas.symget("fpath2"), "w")
    io.input(infile)
    local resp=json.decode(io.read())
    for i, v in pairs(resp["items"]) do
      outfile:write(v.line,"\n")
    end
    io.close(infile)
    io.close(outfile)
  ';
run;
%inc "&fpath3..lua";

/* write log out to the specified fileref */
data _null_;
  infile &fname2 end=last;
  file &outref mod;
  if _n_=1 then do;
    put "/** SASJS Viya Job Log Extract start: &uri **/";
  end;
  input;
  put _infile_;
  %if &mdebug=1 %then %do;
    putlog _infile_;
  %end;
  if last then do;
    put "/** SASJS Viya Job Log Extract end: &uri **/";
  end;
run;

%if &mdebug=0 %then %do;
  filename &fname1 clear;
  filename &fname2 clear;
  filename &fname3 clear;
%end;
%else %do;
  %put &sysmacroname exit vars:;
  %put _local_;
%end;
%mend mv_getjoblog;



/**
  @file
  @brief Extract the result from a completed SAS Viya Job
  @details Extracts result from a Viya job and writes it out to a fileref
  and/or a JSON-engine library.

  To query the job, you need the URI.  Sample code for achieving this
  is provided below.

  ## Example

  First, compile the macros:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  Next, create a job (in this case, a web service):

      filename ft15f001 temp;
      parmcards4;
        data test;
          rand=ranuni(0)*1000;
          do x=1 to rand;
            y=rand*4;
            output;
          end;
        run;
        proc sort data=&syslast
          by descending y;
        run;
        %webout(OPEN)
        %webout(OBJ, test)
        %webout(CLOSE)
      ;;;;
      %mv_createwebservice(path=/Public/temp,name=demo)

  Execute it:

      %mv_jobexecute(path=/Public/temp
        ,name=demo
        ,outds=work.info
      )

  Wait for it to finish, and grab the uri:

      data _null_;
        set work.info;
        if method='GET' and rel='self';
        call symputx('uri',uri);
      run;

  Finally, fetch the result (In this case, WEBOUT):

      %mv_getjobresult(uri=&uri,result=WEBOUT_JSON,outref=myweb,outlib=myweblib)


  @param [in] access_token_var= The global macro variable containing the access
    token
  @param [in] mdebug= set to 1 to enable DEBUG messages
  @param [in] grant_type= valid values:
    @li password
    @li authorization_code
    @li detect - will check if access_token exists, if not will use sas_services
        if a SASStudioV session else authorization_code.  Default option.
    @li sas_services - will use oauth_bearer=sas_services.
  @param [in] uri= The uri of the running job for which to fetch the status,
    in the format `/jobExecution/jobs/$UUID` (unquoted).

  @param [out] result= (WEBOUT_JSON) The result type to capture.  Resolves
  to "_[column name]" from the results table when parsed with the JSON libname
  engine.  Example values:
    @li WEBOUT_JSON
    @li WEBOUT_TXT

  @param [out] outref= (0) The output fileref to which to write the results
  @param [out] outlib= (0) The output library to which to assign the results
    (assumes the data is in JSON format)


  @version VIYA V.03.05
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mp_binarycopy.sas
  @li mf_getplatform.sas
  @li mf_existfileref.sas

**/

%macro mv_getjobresult(uri=0
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,mdebug=0
    ,result=WEBOUT_JSON
    ,outref=0
    ,outlib=0
  );
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)


/* validation in datastep for better character safety */
%local errmsg errflg;
data _null_;
  uri=symget('uri');
  if length(uri)<12 then do;
    call symputx('errflg',1);
    call symputx('errmsg',"URI is invalid (too short) - '&uri'",'l');
  end;
  if scan(uri,-1)='state' or scan(uri,1) ne 'jobExecution' then do;
    call symputx('errflg',1);
    call symputx('errmsg',
      "URI should be in format /jobExecution/jobs/$$$$UUID$$$$"
      !!" but is actually like: &uri",'l');
  end;
run;

%mp_abort(iftrue=(&errflg=1)
  ,mac=&sysmacroname
  ,msg=%str(&errmsg)
)

%if &outref ne 0 and %mf_existfileref(&outref) ne 1 %then %do;
  filename &outref temp;
%end;

options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* fetch job info */
%local fname1;
%let fname1=%mf_getuniquefileref();
proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri&uri";
  headers "Accept"="application/json"
  %if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
  %end;
  ;
run;
%if &SYS_PROCHTTP_STATUS_CODE ne 200 and &SYS_PROCHTTP_STATUS_CODE ne 201 %then
%do;
  data _null_;infile &fname1;input;putlog _infile_;run;
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;
%if &mdebug=1 %then %do;
  data _null_;
    infile &fname1 lrecl=32767;
    input;
    putlog _infile_;
  run;
%end;

/* extract results link */
%local lib1 resuri;
%let lib1=%mf_getuniquelibref();
libname &lib1 JSON fileref=&fname1;
data _null_;
  set &lib1..results;
  call symputx('resuri',_&result,'l');
  &dbg putlog "&sysmacroname results: " (_all_)(=);
run;
%mp_abort(iftrue=("&resuri"=".")
  ,mac=&sysmacroname
  ,msg=%str(Variable _&result did not exist in the response json)
)

/* extract results */
%local fname2;
%let fname2=%mf_getuniquefileref();
proc http method='GET' out=&fname2 &oauth_bearer
  url="&base_uri&resuri/content?limit=10000";
  headers "Accept"="application/json"
  %if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
  %end;
  ;
run;
%if &mdebug=1 %then %do;
  /* send one char at a time as the json can be very wide */
  data _null_;
    infile &fname2 recfm=n;
    input char $char1. ;
    putlog char $char1. @;
  run;
%end;

%if &outref ne 0 %then %do;
  filename &outref temp;
  %mp_binarycopy(inref=&fname2,outref=&outref)
%end;
%if &outlib ne 0 %then %do;
  libname &outlib JSON fileref=&fname2;
%end;

%if &mdebug=0 %then %do;
  filename &fname1 clear;
  filename &fname2 clear;
  libname &lib1 clear;
%end;
%else %do;
  %put &sysmacroname exit vars:;
  %put _local_;
%end;

%mend mv_getjobresult;
/**
  @file
  @brief Extract the status from a running SAS Viya job
  @details Extracts the status from a running job and appends it to an output
  dataset with the following structure:

      | uri                                                           | state   | timestamp          |
      |---------------------------------------------------------------|---------|--------------------|
      | /jobExecution/jobs/5cebd840-2063-42c1-be0c-421ec3e1c175/state | running | 15JAN2021:12:35:08 |

  To query the running job, you need the URI.  Sample code for achieving this
  is provided below.

  ## Example

  First, compile the macros:

      filename mc url "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  Next, create a long running job (in this case, a web service):

      filename ft15f001 temp;
      parmcards4;
        data ;
          rand=ranuni(0)*1000;
          do x=1 to rand;
            y=rand*4;
            output;
          end;
        run;
        data _null_;
          call sleep(5,1);
        run;
      ;;;;
      %mv_createwebservice(path=/Public/temp,name=demo)

  Execute it, grab the uri, and finally, check the job status:

      %mv_jobexecute(path=/Public/temp
        ,name=demo
        ,outds=work.info
      )

      data _null_;
        set work.info;
        if method='GET' and rel='state';
        call symputx('uri',uri);
      run;

      %mv_getjobstate(uri=&uri,outds=results)

  You can run this macro as part of a loop to await the final 'completed' status.
  The full list of status values is:

  @li idle
  @li pending
  @li running
  @li canceled
  @li completed
  @li failed

  If you have one or more jobs that you'd like to wait for completion you can
  also use the [mv_jobwaitfor](/mv__jobwaitfor_8sas.html) macro.

  @param [in] access_token_var= The global macro variable to contain the access token
  @param [in] grant_type= valid values:
    @li password
    @li authorization_code
    @li detect - will check if access_token exists, if not will use sas_services if
        a SASStudioV session else authorization_code.  Default option.
    @li sas_services - will use oauth_bearer=sas_services.
  @param [in] uri= The uri of the running job for which to fetch the status,
    in the format `/jobExecution/jobs/$UUID/state` (unquoted).
  @param [out] outds= The output dataset in which to APPEND the status. Three
    fields are appended:  `CHECK_TM`, `URI` and `STATE`. If the dataset does not
    exist, it is created.


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas

**/

%macro mv_getjobstate(uri=0,outds=work.mv_getjobstate
    ,contextName=SAS Job Execution compute context
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

/* validation in datastep for better character safety */
%local errmsg errflg;
data _null_;
  uri=symget('uri');
  if length(uri)<12 then do;
    call symputx('errflg',1);
    call symputx('errmsg',"URI is invalid (too short) - '&uri'",'l');
  end;
  if scan(uri,-1) ne 'state' or scan(uri,1) ne 'jobExecution' then do;

    call symputx('errflg',1);
    call symputx('errmsg',
      "URI should be in format /jobExecution/jobs/$$$$UUID$$$$/state"
      !!" but is actually like: &uri",'l');
  end;
run;

%mp_abort(iftrue=(&errflg=1)
  ,mac=&sysmacroname
  ,msg=%str(&errmsg)
)

options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

%local fname0;
%let fname0=%mf_getuniquefileref();

proc http method='GET' out=&fname0 &oauth_bearer url="&base_uri/&uri";
  headers "Accept"="text/plain"
  %if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
  %end;  ;
run;
%if &SYS_PROCHTTP_STATUS_CODE ne 200 and &SYS_PROCHTTP_STATUS_CODE ne 201 %then
%do;
  data _null_;infile &fname0;input;putlog _infile_;run;
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;

data;
  format uri $128. state $32. timestamp datetime19.;
  infile &fname0;
  uri="&uri";
  timestamp=datetime();
  input;
  state=_infile_;
run;

proc append base=&outds data=&syslast;
run;

filename &fname0 clear;

%mend mv_getjobstate;
/**
  @file mv_getrefreshtoken.sas
  @brief deprecated - replaced by mv_tokenauth.sas

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mv_tokenauth.sas

**/

%macro mv_getrefreshtoken(client_id=someclient
    ,client_secret=somesecret
    ,grant_type=authorization_code
    ,code=
    ,user=
    ,pass=
    ,access_token_var=ACCESS_TOKEN
    ,refresh_token_var=REFRESH_TOKEN
  );

%mv_tokenauth(client_id=&client_id
  ,client_secret=&client_secret
  ,grant_type=&grant_type
  ,code=&code
  ,user=&user
  ,pass=&pass
  ,access_token_var=&access_token_var
  ,refresh_token_var=&refresh_token_var
)

%mend mv_getrefreshtoken;/**
  @file mv_getusergroups.sas
  @brief Creates a dataset with a list of groups for a particular user
  @details If using outside of Viya SPRE, then an access token is needed.

  Compile the macros here:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  Then run the macro!

      %mv_getusergroups(&sysuserid,outds=users)

  @param access_token_var= The global macro variable to contain the access token
  @param grant_type= valid values are "password" or "authorization_code" (unquoted).
    The default is authorization_code.
  @param outds= The library.dataset to be created that contains the list of groups


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas

**/

%macro mv_getusergroups(user
    ,outds=work.mv_getusergroups
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;
%put &sysmacroname: grant_type=&grant_type;
%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)
options noquotelenmax;

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* fetching folder details for provided path */
%local fname1;
%let fname1=%mf_getuniquefileref();
%let libref1=%mf_getuniquelibref();

proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri/identities/users/&user/memberships?limit=10000";
  headers
%if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
%end;
          "Accept"="application/json";
run;
/*data _null_;infile &fname1;input;putlog _infile_;run;*/
%if &SYS_PROCHTTP_STATUS_CODE=404 %then %do;
  %put NOTE:  User &user not found!!;
%end;
%else %do;
  %mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
    ,mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;
libname &libref1 JSON fileref=&fname1;

data &outds;
  set &libref1..items;
run;

/* clear refs */
filename &fname1 clear;
libname &libref1 clear;

%mend mv_getusergroups;/**
  @file mv_getusers.sas
  @brief Creates a dataset with a list of users
  @details First, be sure you have an access token (which requires an app token).

  Using the macros here:

      filename mc url
      "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  An administrator needs to set you up with an access code:

      %mv_registerclient(outds=client)

  Navigate to the url from the log (opting in to the groups) and paste the
  access code below:

      %mv_tokenauth(inds=client,code=wKDZYTEPK6)

  Now we can run the macro!

      %mv_getusers(outds=users)

  Output (lengths are dynamic):

      ordinal_root num,
      ordinal_items num,
      version num,
      id char(20),
      name char(23),
      providerId char(4),
      type char(4),
      creationTimeStamp char(24),
      modifiedTimeStamp char(24),
      state char(6)

  @param access_token_var= The global macro variable to contain the access token
  @param grant_type= valid values:
    * password
    * authorization_code
    * detect - will check if access_token exists, if not will use sas_services if
      a SASStudioV session else authorization_code.  Default option.
    * sas_services - will use oauth_bearer=sas_services

  @param outds= The library.dataset to be created that contains the list of groups


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas

**/

%macro mv_getusers(outds=work.mv_getusers
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
  );
%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;
%put &sysmacroname: grant_type=&grant_type;
%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

options noquotelenmax;

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* fetching folder details for provided path */
%local fname1;
%let fname1=%mf_getuniquefileref();
%let libref1=%mf_getuniquelibref();

proc http method='GET' out=&fname1 &oauth_bearer
  url="&base_uri/identities/users?limit=10000";
%if &grant_type=authorization_code %then %do;
  headers "Authorization"="Bearer &&&access_token_var"
          "Accept"="application/json";
%end;
%else %do;
  headers "Accept"="application/json";
%end;
run;
/*data _null_;infile &fname1;input;putlog _infile_;run;*/
%mp_abort(iftrue=(&SYS_PROCHTTP_STATUS_CODE ne 200)
  ,mac=&sysmacroname
  ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
)
libname &libref1 JSON fileref=&fname1;

data &outds;
  set &libref1..items;
run;

/* clear refs */
filename &fname1 clear;
libname &libref1 clear;

%mend mv_getusers;/**
  @file
  @brief Executes a SAS Viya Job
  @details Triggers a SAS Viya Job, with optional URL parameters, using
  the JES web app.

  First, compile the macros:

      filename mc url
      "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  Then, execute the job!

      %mv_jobexecute(path=/Public/folder
        ,name=somejob
      )

  Example with parameters:

      %mv_jobexecute(path=/Public/folder
        ,name=somejob
        ,paramstring=%str("macvarname":"macvarvalue","answer":42)
      )

  @param [in] access_token_var= The global macro variable to contain the access
    token
  @param [in] grant_type= valid values:
    @li password
    @li authorization_code
    @li detect - will check if access_token exists, if not will use sas_services
      if a SASStudioV session else authorization_code.  Default option.
    @li sas_services - will use oauth_bearer=sas_services

  @param [in] path= The SAS Drive path to the job being executed
  @param [in] name= The name of the job to execute
  @param [in] paramstring= A JSON fragment with name:value pairs, eg:
    `"name":"value"` or "name":"value","name2":42`.  This will need to be
    wrapped in `%str()`.

  @param [in] contextName= Context name with which to run the job.
    Default = `SAS Job Execution compute context`
  @param [in] mdebug= set to 1 to enable DEBUG messages
  @param [out] outds= (work.mv_jobexecute) The output dataset containing links


  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mv_getfoldermembers.sas

**/

%macro mv_jobexecute(path=0
    ,name=0
    ,contextName=SAS Job Execution compute context
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,paramstring=0
    ,outds=work.mv_jobexecute
    ,mdebug=0
  );
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%mp_abort(iftrue=("&path"="0")
  ,mac=&sysmacroname
  ,msg=%str(Path not provided)
)
%mp_abort(iftrue=("&name"="0")
  ,mac=&sysmacroname
  ,msg=%str(Job Name not provided)
)

options noquotelenmax;

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

data;run;
%local foldermembers;
%let foldermembers=&syslast;
%mv_getfoldermembers(root=&path
    ,access_token_var=&access_token_var
    ,grant_type=&grant_type
    ,outds=&foldermembers
)

%local joburi;
%let joburi=0;
data _null_;
  length name uri $512;
  call missing(name,uri);
  set &foldermembers;
  if name="&name" and uri=:'/jobDefinitions/definitions'
    then call symputx('joburi',uri);
run;

%mp_abort(iftrue=("&joburi"="0")
  ,mac=&sysmacroname
  ,msg=%str(Job &path/&name not found)
)

/* prepare request*/
%local fname0 fname1;
%let fname0=%mf_getuniquefileref();
%let fname1=%mf_getuniquefileref();

data _null_;
  file &fname0;
  length joburi contextname $128 paramstring $32765;
  joburi=quote(trim(symget('joburi')));
  contextname=quote(trim(symget('contextname')));
  _program=quote("&path/&name");
  paramstring=symget('paramstring');
  put '{"jobDefinitionUri":' joburi ;
  put '  ,"arguments":{"_contextName":' contextname;
  put '    ,"_program":' _program;
  if paramstring ne "0" then do;
    put '    ,' paramstring;
  end;
  put '}}';
run;

proc http method='POST' in=&fname0 out=&fname1 &oauth_bearer
  url="&base_uri/jobExecution/jobs";
  headers "Content-Type"="application/vnd.sas.job.execution.job.request+json"
          "Accept"="application/vnd.sas.job.execution.job+json"
  %if &grant_type=authorization_code %then %do;
          "Authorization"="Bearer &&&access_token_var"
  %end;
  ;
run;
%if &SYS_PROCHTTP_STATUS_CODE ne 200 and &SYS_PROCHTTP_STATUS_CODE ne 201 %then
%do;
  data _null_;infile &fname0;input;putlog _infile_;run;
  data _null_;infile &fname1;input;putlog _infile_;run;
  %mp_abort(mac=&sysmacroname
    ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
  )
%end;

%local libref;
%let libref=%mf_getuniquelibref();
libname &libref JSON fileref=&fname1;

data &outds;
  set &libref..links;
  _program="&path/&name";
run;

%if &mdebug=1 %then %do;
  %put &sysmacroname exit vars:;
  %put _local_;
%end;
%else %do;
  /* clear refs */
  filename &fname0 clear;
  filename &fname1 clear;
  libname &libref;
%end;
%mend mv_jobexecute;/**
  @file
  @brief Execute a series of job flows
  @details Very (very) simple flow manager.  Jobs execute in sequential waves,
  all previous waves must finish successfully.

  The input table is formed as per below.  Each observation represents one job.
  Each variable is converted into a macro variable with the same name.

  ## Input table (minimum variables needed)

  @li _PROGRAM - Provides the path to the job itself
  @li FLOW_ID - Numeric value, provides sequential ordering capability. Is
    optional, will default to 0 if not provided.
  @li _CONTEXTNAME - Dictates which context should be used to run the job. If
    blank, or not provided, will default to `SAS Job Execution compute context`.

  Any additional variables provided in this table are converted into macro
  variables and passed into the relevant job.

  |_PROGRAM| FLOW_ID (optional)| _CONTEXTNAME (optional) |
  |---|---|---|
  |/Public/jobs/somejob1|0|SAS Job Execution compute context|
  |/Public/jobs/somejob2|0|SAS Job Execution compute context|

  ## Output table (minimum variables produced)

  @li _PROGRAM - the SAS Drive path of the job
  @li URI - the URI of the executed job
  @li STATE - the completed state of the job
  @li TIMESTAMP - the datetime that the job completed
  @li JOBPARAMS - the parameters that were passed to the job
  @li FLOW_ID - the id of the flow in which the job was executed

  ![https://i.imgur.com/nZE9PvT.png](https://i.imgur.com/nZE9PvT.png)

  To avoid hammering the box with many hits in rapid succession, a one
  second pause is made between every request.


  ## Example

  First, compile the macros:

      filename mc url
      "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  Next, create some jobs (in this case, as web services):

      filename ft15f001 temp;
      parmcards4;
        %put this is job: &_program;
        %put this was run in flow &flow_id;
        data ;
          rand=ranuni(0)*&macrovar1;
          do x=1 to rand;
            y=rand*&macrovar2;
            if y=100 then abort;
            output;
          end;
        run;
      ;;;;
      %mv_createwebservice(path=/Public/temp,name=demo1)
      %mv_createwebservice(path=/Public/temp,name=demo2)

  Prepare an input table with 60 executions:

      data work.inputjobs;
        _contextName='SAS Job Execution compute context';
        do flow_id=1 to 3;
          do i=1 to 20;
            _program='/Public/temp/demo1';
            macrovar1=10*i;
            macrovar2=4*i;
            output;
            i+1;
            _program='/Public/temp/demo2';
            macrovar1=40*i;
            macrovar2=44*i;
            output;
          end;
        end;
      run;

  Trigger the flow

      %mv_jobflow(inds=work.inputjobs
        ,maxconcurrency=4
        ,outds=work.results
        ,outref=myjoblog
      )

      data _null_;
        infile myjoblog;
        input; put _infile_;
      run;


  @param [in] access_token_var= The global macro variable to contain the
              access token
  @param [in] grant_type= valid values:
      @li password
      @li authorization_code
      @li detect - will check if access_token exists, if not will use
        sas_services if a SASStudioV session else authorization_code.  Default
        option.
      @li sas_services - will use oauth_bearer=sas_services
  @param [in] inds= The input dataset containing a list of jobs and parameters
  @param [in] maxconcurrency= The max number of parallel jobs to run. Default=8.
  @param [in] raise_err=0 Set to 1 to raise SYSCC when a job does not complete
            succcessfully
  @param [in] mdebug= set to 1 to enable DEBUG messages
  @param [out] outds= The output dataset containing the results
  @param [out] outref= The output fileref to which to append the log file(s).

  @version VIYA V.03.05
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mf_nobs.sas
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_existvarlist.sas
  @li mv_jobwaitfor.sas
  @li mv_jobexecute.sas

**/

%macro mv_jobflow(inds=0,outds=work.mv_jobflow
    ,maxconcurrency=8
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,outref=0
    ,raise_err=0
    ,mdebug=0
  );
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
  %put inds vars:;
  data _null_;
    set &inds;
    putlog (_all_)(=);
  run;
%end;
%else %let dbg=*;

%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%mp_abort(iftrue=("&inds"="0")
  ,mac=&sysmacroname
  ,msg=%str(Input dataset was not provided)
)
%mp_abort(iftrue=(%mf_existVarList(&inds,_PROGRAM)=0)
  ,mac=&sysmacroname
  ,msg=%str(The _PROGRAM column must exist on input dataset &inds)
)
%mp_abort(iftrue=(&maxconcurrency<1)
  ,mac=&sysmacroname
  ,msg=%str(The maxconcurrency variable should be a positive integer)
)

/* set defaults if not provided */
%if %mf_existVarList(&inds,_CONTEXTNAME FLOW_ID)=0 %then %do;
  data &inds;
    %if %mf_existvarList(&inds,_CONTEXTNAME)=0 %then %do;
      length _CONTEXTNAME $128;
      retain _CONTEXTNAME "SAS Job Execution compute context";
    %end;
    %if %mf_existvarList(&inds,FLOW_ID)=0 %then %do;
      retain FLOW_ID 0;
    %end;
    set &inds;
    &dbg. putlog (_all_)(=);
  run;
%end;

%local missings;
proc sql noprint;
select count(*) into: missings
  from &inds
  where flow_id is null or _program is null;
%mp_abort(iftrue=(&missings>0)
  ,mac=&sysmacroname
  ,msg=%str(input dataset has &missings missing values for FLOW_ID or _PROGRAM)
)

%if %mf_nobs(&inds)=0 %then %do;
  %put No observations in &inds!  Leaving macro &sysmacroname;
  %return;
%end;

/* ensure output table is available */
data &outds;run;
proc sql;
drop table &outds;

options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);


/* get flows */
proc sort data=&inds;
  by flow_id;
run;
data _null_;
  set &inds (keep=flow_id) end=last;
  by flow_id;
  if last.flow_id then do;
    cnt+1;
    call symputx(cats('flow',cnt),flow_id,'l');
  end;
  if last then call symputx('flowcnt',cnt,'l');
run;

/* prepare temporary datasets and frefs */
%local fid jid jds jjson jdsapp jdsrunning jdswaitfor jfref;
data;run;%let jds=&syslast;
data;run;%let jjson=&syslast;
data;run;%let jdsapp=&syslast;
data;run;%let jdsrunning=&syslast;
data;run;%let jdswaitfor=&syslast;
%let jfref=%mf_getuniquefileref();

/* start loop */
%do fid=1 %to &flowcnt;

  %if not ( &raise_err and &syscc ) %then %do;

    %put preparing job attributes for flow &&flow&fid;
    %local jds jcnt;
    data &jds(drop=_contextName _program);
      set &inds(where=(flow_id=&&flow&fid));
      if _contextName='' then _contextName="SAS Job Execution compute context";
      call symputx(cats('job',_n_),_program,'l');
      call symputx(cats('context',_n_),_contextName,'l');
      call symputx('jcnt',_n_,'l');
      &dbg. if _n_= 1 then putlog "Loop &fid";
      &dbg. putlog (_all_)(=);
    run;
    %put exporting job variables in json format;
    %do jid=1 %to &jcnt;
      data &jjson;
        set &jds;
        if _n_=&jid then do;
          output;
          stop;
        end;
      run;
      proc json out=&jfref;
        export &jjson / nosastags fmtnumeric;
      run;
      data _null_;
        infile &jfref lrecl=32767;
        input;
        jparams='jparams'!!left(symget('jid'));
        call symputx(jparams,substr(_infile_,3,length(_infile_)-4));
      run;
      %local jobuid&jid;
      %let jobuid&jid=0; /* used in next loop */
    %end;
    %local concurrency completed;
    %let concurrency=0;
    %let completed=0;
    proc sql; drop table &jdsrunning;
    %do jid=1 %to &jcnt;
      /**
        * now we can execute the jobs up to the maxconcurrency setting
        */
      %if "&&job&jid" ne "0" %then %do; /* this var is zero if job finished */

        /* check to see if the job finished in the previous round */
        %if %sysfunc(exist(&outds))=1 %then %do;
          %local jobcheck;  %let jobcheck=0;
          proc sql noprint;
          select count(*) into: jobcheck
            from &outds where uuid="&&jobuid&jid";
          %if &jobcheck>0 %then %do;
            %put &&job&jid in flow &fid with uid &&jobuid&jid completed!;
            %let job&jid=0;
          %end;
        %end;

        /* check if job was triggered and, if
            so, if we have enough slots to run? */
        %if ("&&jobuid&jid"="0") and (&concurrency<&maxconcurrency) %then %do;

          /* But only start if no issues detected so far */
          %if not ( &raise_err and &syscc ) %then %do;

            %local jobname jobpath;
            %let jobname=%scan(&&job&jid,-1,/);
            %let jobpath=
                  %substr(&&job&jid,1,%length(&&job&jid)-%length(&jobname)-1);

            %put executing &jobpath/&jobname with paramstring &&jparams&jid;
            %mv_jobexecute(path=&jobpath
              ,name=&jobname
              ,paramstring=%superq(jparams&jid)
              ,outds=&jdsapp
              ,contextname=&&context&jid
            )
            data &jdsapp;
              format jobparams $32767.;
              set &jdsapp(where=(method='GET' and rel='state'));
              jobparams=symget("jparams&jid");
              /* uri here has the /state suffix */
              uuid=scan(uri,-2,'/');
              call symputx("jobuid&jid",uuid,'l');
            run;
            proc append base=&jdsrunning data=&jdsapp;
            run;
            %let concurrency=%eval(&concurrency+1);
            /* sleep one second after every request to smooth the impact */
            data _null_;
              call sleep(1,1);
            run;

          %end;
          %else %do; /* Job was skipped due to problems */

            %put jobid &&job&jid in flow &fid skipped due to SYSCC (&syscc);
            %let completed = %eval(&completed+1);
            %let job&jid=0; /* Indicate job has finished */

          %end;

        %end;
      %end;
      %if &jid=&jcnt %then %do;
        /* we are at the end of the loop - check which jobs have finished */
        %mv_jobwaitfor(ANY,inds=&jdsrunning,outds=&jdswaitfor,outref=&outref
                      ,raise_err=&raise_err,mdebug=&mdebug)
        %local done;
        %let done=%mf_nobs(&jdswaitfor);
        %if &done>0 %then %do;
          %let completed=%eval(&completed+&done);
          %let concurrency=%eval(&concurrency-&done);
          data &jdsapp;
            set &jdswaitfor;
            flow_id=&&flow&fid;
            uuid=scan(uri,-1,'/');
          run;
          proc append base=&outds data=&jdsapp;
          run;
        %end;
        proc sql;
        delete from &jdsrunning
          where uuid in (select uuid from &outds
            where state in ('canceled','completed','failed')
          );

        /* loop again if jobs are left */
        %if &completed < &jcnt %then %do;
          %let jid=0;
          %put looping flow &fid again;
          %put &completed of &jcnt jobs completed, &concurrency jobs running;
        %end;
      %end;
    %end;

  %end;
  %else %do;

    %put Flow &&flow&fid skipped due to SYSCC (&syscc);

  %end;
  /* back up and execute the next flow */
%end;

%if &mdebug=1 %then %do;
  %put &sysmacroname exit vars:;
  %put _local_;
%end;

%mend mv_jobflow;
/**
  @file
  @brief Takes a table of running jobs and waits for ANY/ALL of them to complete
  @details Will poll `/jobs/{jobId}/state` at set intervals until ANY or ALL
  jobs are completed.  Completion is determined by reference to the returned
  _state_, as per the following table:

  | state     | Wait? | Notes|
  |-----------|-------|------|
  | idle      | yes   | We assume processing will continue. Beware of idle sessions with no code submitted! |
  | pending   | yes   | Job is preparing to run |
  | running   | yes   | Job is running|
  | canceled  | no    | Job was cancelled|
  | completed | no    | Job finished - does not mean it was successful.  Check stateDetails|
  | failed    | no    | Job failed to execute, could be a problem when calling the apis|


  ## Example

  First, compile the macros:

      filename mc url
      "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

  Next, create a job (in this case, as a web service):

      filename ft15f001 temp;
      parmcards4;
        data ;
          rand=ranuni(0)*1000000;
          do x=1 to rand;
            y=rand*x;
            output;
          end;
        run;
      ;;;;
      %mv_createwebservice(path=/Public/temp,name=demo)

  Then, execute the job,multiple times, and wait for them all to finish:

      %mv_jobexecute(path=/Public/temp,name=demo,outds=work.ds1)
      %mv_jobexecute(path=/Public/temp,name=demo,outds=work.ds2)
      %mv_jobexecute(path=/Public/temp,name=demo,outds=work.ds3)
      %mv_jobexecute(path=/Public/temp,name=demo,outds=work.ds4)

      data work.jobs;
        set work.ds1 work.ds2 work.ds3 work.ds4;
        where method='GET' and rel='state';
      run;

      %mv_jobwaitfor(ALL,inds=work.jobs,outds=work.jobstates)

  Delete the job:

      %mv_deletejes(path=/Public/temp,name=demo)

  @param [in] access_token_var= The global macro variable to contain the access
    token
  @param [in] grant_type= valid values:

      - password
      - authorization_code
      - detect - will check if access_token exists, if not will use sas_services
        if a SASStudioV session else authorization_code.  Default option.
      - sas_services - will use oauth_bearer=sas_services

  @param [in] action=Either ALL (to wait for every job) or ANY (if one job
    completes, processing will continue).  Default=ALL.
  @param [in] inds= The input dataset containing the list of job uris, in the
    following format:  `/jobExecution/jobs/&JOBID./state` and the corresponding
    job name.  The uri should be in a `uri` variable, and the job path/name
    should be in a `_program` variable.
  @param [in] raise_err=0 Set to 1 to raise SYSCC when a job does not complete
              succcessfully
  @param [in] mdebug= set to 1 to enable DEBUG messages
  @param [out] outds= The output dataset containing the list of states by job
    (default=work.mv_jobexecute)
  @param [out] outref= A fileref to which the spawned job logs should be
    appended.

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> Dependencies </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_existvar.sas
  @li mf_nobs.sas
  @li mv_getjoblog.sas

**/

%macro mv_jobwaitfor(action
    ,access_token_var=ACCESS_TOKEN
    ,grant_type=sas_services
    ,inds=0
    ,outds=work.mv_jobwaitfor
    ,outref=0
    ,raise_err=0
    ,mdebug=0
  );
%local dbg;
%if &mdebug=1 %then %do;
  %put &sysmacroname entry vars:;
  %put _local_;
%end;
%else %let dbg=*;

%local oauth_bearer;
%if &grant_type=detect %then %do;
  %if %symexist(&access_token_var) %then %let grant_type=authorization_code;
  %else %let grant_type=sas_services;
%end;
%if &grant_type=sas_services %then %do;
    %let oauth_bearer=oauth_bearer=sas_services;
    %let &access_token_var=;
%end;

%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password
    and &grant_type ne sas_services
  )
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%mp_abort(iftrue=("&inds"="0")
  ,mac=&sysmacroname
  ,msg=%str(input dataset not provided)
)
%mp_abort(iftrue=(%mf_existvar(&inds,uri)=0)
  ,mac=&sysmacroname
  ,msg=%str(The URI variable was not found in the input dataset(&inds))
)
%mp_abort(iftrue=(%mf_existvar(&inds,_program)=0)
  ,mac=&sysmacroname
  ,msg=%str(The _PROGRAM variable was not found in the input dataset(&inds))
)

%if %mf_nobs(&inds)=0 %then %do;
  %put NOTE: Zero observations in &inds, &sysmacroname will now exit;
  %return;
%end;

options noquotelenmax;
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

data _null_;
  length jobparams $32767;
  set &inds end=last;
  call symputx(cats('joburi',_n_),substr(uri,1,55),'l');
  call symputx(cats('jobname',_n_),_program,'l');
  call symputx(cats('jobparams',_n_),jobparams,'l');
  if last then call symputx('uricnt',_n_,'l');
run;

%local runcnt;
%if &action=ALL %then %let runcnt=&uricnt;
%else %if &action=ANY %then %let runcnt=1;
%else %let runcnt=&uricnt;

%local fname0 ;
%let fname0=%mf_getuniquefileref();

data &outds;
  format _program uri $128. state $32. stateDetails $32. timestamp datetime19.
    jobparams $32767.;
  call missing (of _all_);
  stop;
run;

%local i;
%do i=1 %to &uricnt;
  %if "&&joburi&i" ne "0" %then %do;
    proc http method='GET' out=&fname0 &oauth_bearer url="&base_uri/&&joburi&i";
      headers "Accept"="application/json"
      %if &grant_type=authorization_code %then %do;
              "Authorization"="Bearer &&&access_token_var"
      %end;  ;
    run;
    %if &SYS_PROCHTTP_STATUS_CODE ne 200 and &SYS_PROCHTTP_STATUS_CODE ne 201
    %then %do;
      data _null_;infile &fname0;input;putlog _infile_;run;
      %mp_abort(mac=&sysmacroname
        ,msg=%str(&SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE)
      )
    %end;

    %let status=notset;

    %local libref1;
    %let libref1=%mf_getuniquelibref();
    libname &libref1 json fileref=&fname0;

    data _null_;
      length state stateDetails $32;
      set &libref1..root;
      call symputx('status',state,'l');
      call symputx('stateDetails',stateDetails,'l');
    run;

    libname &libref1 clear;

    %if &status=completed or &status=failed or &status=canceled %then %do;
      %local plainuri;
      %let plainuri=%substr(&&joburi&i,1,55);
      proc sql;
      insert into &outds set
        _program="&&jobname&i",
        uri="&plainuri",
        state="&status",
        stateDetails=symget("stateDetails"),
        timestamp=datetime(),
        jobparams=symget("jobparams&i");
      %let joburi&i=0; /* do not re-check */
      /* fetch log */
      %if %str(&outref) ne 0 %then %do;
        %mv_getjoblog(uri=&plainuri,outref=&outref,mdebug=&mdebug)
      %end;
    %end;
    %else %if &status=idle or &status=pending or &status=running %then %do;
      data _null_;
        call sleep(1,1);
      run;
    %end;
    %else %do;
      %mp_abort(mac=&sysmacroname
        ,msg=%str(status &status not expected!!)
      )
    %end;

    %if (&raise_err) %then %do;
      %if (&status = canceled or &status = failed or %length(&stateDetails)>0)
      %then %do;
        %if ("&stateDetails" = "%str(war)ning") %then %let SYSCC=4;
        %else %let SYSCC=5;
        %put %str(ERR)OR: Job &&jobname&i. did not complete. &stateDetails;
        %return;
      %end;
    %end;

  %end;
  %if &i=&uricnt %then %do;
    %local goback;
    %let goback=0;
    proc sql noprint;
    select count(*) into:goback from &outds;
    %if &goback lt &runcnt %then %let i=0;
  %end;
%end;

%if &mdebug=1 %then %do;
  %put &sysmacroname exit vars:;
  %put _local_;
%end;
%else %do;
  /* clear refs */
  filename &fname0 clear;
%end;
%mend mv_jobwaitfor;/**
  @file mv_registerclient.sas
  @brief Register Client and Secret (admin task)
  @details When building apps on SAS Viya, an client id and secret are sometimes
  required.  In order to generate them, filesystem access to the Consul Token
  is needed (it is not enough to be in the SASAdministrator group in SAS
  Environment Manager).

  If you are registering a lot of clients / secrets, you may find it more
  convenient to use the [Viya Token Generator]
  (https://sasjs.io/apps/#viya-client-token-generator) (a SASjs Web App to
  automate the generation of clients & secrets with various settings).

  For further information on clients / secrets, see;
  @li https://developer.sas.com/reference/auth/#register
  @li https://proc-x.com/2019/01/authentication-to-sas-viya-a-couple-of-approaches
  @li https://cli.sasjs.io/faq/#how-can-i-obtain-a-viya-client-and-secret

  The default viyaroot location is: `/opt/sas/viya/config`

  Usage:

      %* compile macros;
      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;

      %* specific client with just openid scope;
      %mv_registerclient(client_id=YourClient
        ,client_secret=YourSecret
        ,scopes=openid
      )

      %* generate random client details with all scopes;
      %mv_registerclient(scopes=openid *)

      %* generate random client with 90/180 second access/refresh token expiry;
      %mv_registerclient(scopes=openid *
        ,access_token_validity=90
        ,refresh_token_validity=180
      )

  @param client_id= The client name.  Auto generated if blank.
  @param client_secret= Client secret.  Auto generated if client is blank.
  @param scopes=(openid) List of space-seperated unquoted scopes
  @param grant_type=(authorization_code|refresh_token) Valid values are
    "password" or "authorization_code" (unquoted)
  @param outds=(mv_registerclient) The dataset to contain the registered client
    id and secret
  @param access_token_validity=(DEFAULT) The duration of validity of the access
    token in seconds.  A value of DEFAULT will omit the entry (and use system
    default)
  @param refresh_token_validity=(DEFAULT)  The duration of validity of the
    refresh token in seconds.  A value of DEFAULT will omit the entry (and use
    system default)
  @param name= An optional, human readable name for the client
  @param required_user_groups= A list of group names. If a user does not belong
    to all the required groups, the user will not be authenticated and no tokens
    are issued to this client for that user. If this field is not specified,
    authentication and token issuance proceeds normally.
  @param autoapprove= During the auth step the user can choose which scope to
    apply.  Setting this to true will autoapprove all the client scopes.
  @param use_session= If true, access tokens issued to this client will be
    associated with an HTTP session and revoked upon logout or time-out.
  @param outjson= (_null_) A dataset containing the lines of JSON submitted.
    Useful for debugging.

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_loc.sas
  @li mf_getquotedstr.sas
  @li mf_getuser.sas

**/

%macro mv_registerclient(client_id=
    ,client_secret=
    ,client_name=DEFAULT
    ,scopes=openid
    ,grant_type=authorization_code|refresh_token
    ,required_user_groups=
    ,autoapprove=
    ,use_session=
    ,outds=mv_registerclient
    ,access_token_validity=DEFAULT
    ,refresh_token_validity=DEFAULT
    ,outjson=_null_
  );
%local consul_token fname1 fname2 fname3 libref access_token url tokloc;

%if client_name=DEFAULT %then %let client_name=
  Generated by %mf_getuser() on %sysfunc(datetime(),datetime19.) using SASjs;

options noquotelenmax;
/* first, get consul token needed to get client id / secret */
%let tokloc=/etc/SASSecurityCertificateFramework/tokens/consul/default;
%let tokloc=%mf_loc(VIYACONFIG)&tokloc/client.token;


%mp_abort(iftrue=(%sysfunc(fileexist(&tokloc))=0)
  ,mac=&sysmacroname
  ,msg=%str(Unable to access the consul token at &tokloc)
)

%let consul_token=0;
data _null_;
  infile "&tokloc";
  input token:$64.;
  call symputx('consul_token',token);
run;

%mp_abort(iftrue=("&consul_token"="0")
  ,mac=&sysmacroname
  ,msg=%str(Unable to source the consul token from &tokloc)
)

%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

/* request the client details */
%let fname1=%mf_getuniquefileref();
proc http method='POST' out=&fname1
  url="&base_uri/SASLogon/oauth/clients/consul?callback=false%str(&)%trim(
    )serviceId=app";
  headers "X-Consul-Token"="&consul_token";
run;

%let libref=%mf_getuniquelibref();
libname &libref JSON fileref=&fname1;

/* extract the token */
data _null_;
  set &libref..root;
  call symputx('access_token',access_token,'l');
run;

/**
  * register the new client
  */
%let fname2=%mf_getuniquefileref();
%if x&client_id.x=xx %then %do;
  %let client_id=client_%sysfunc(ranuni(0),hex16.);
  %let client_secret=secret_%sysfunc(ranuni(0),hex16.);
%end;

%let scopes=%sysfunc(coalescec(&scopes,openid));
%let scopes=%mf_getquotedstr(&scopes,QUOTE=D,indlm=|);
%let grant_type=%mf_getquotedstr(&grant_type,QUOTE=D,indlm=|);
%let required_user_groups=
  %mf_getquotedstr(&required_user_groups,QUOTE=D,indlm=|);

data _null_;
  file &fname2;
  length clientid clientsecret clientname scope grant_types reqd_groups
    autoapprove $256.;
  clientid='"client_id":'!!quote(trim(symget('client_id')));
  clientsecret=',"client_secret":'!!quote(trim(symget('client_secret')));
  clientname=',"name":'!!quote(trim(symget('client_name')));
  scope=',"scope":['!!symget('scopes')!!']';
  grant_types=symget('grant_type');
  if grant_types = '""' then grant_types ='';
  grant_types=cats(',"authorized_grant_types": [',grant_types,']');
  reqd_groups=symget('required_user_groups');
  if reqd_groups = '""' then reqd_groups ='';
  else reqd_groups=cats(',"required_user_groups":[',reqd_groups,']');
  autoapprove=trim(symget('autoapprove'));
  if not missing(autoapprove) then autoapprove=
    cats(',"autoapprove":',autoapprove);
  use_session=trim(symget('use_session'));
  if not missing(use_session) then use_session=
    cats(',"use_session":',use_session);

  put '{'  clientid  ;
  put clientsecret ;
  put clientname;
  put scope;
  put grant_types;
  if not missing(reqd_groups) then put reqd_groups;
  put autoapprove;
  put use_session;
%if &access_token_validity ne DEFAULT %then %do;
  put ',"access_token_validity":' "&access_token_validity";
%end;
%if &refresh_token_validity ne DEFAULT %then %do;
  put  ',"refresh_token_validity":' "&refresh_token_validity";
%end;

  put ',"redirect_uri": "urn:ietf:wg:oauth:2.0:oob"';
  put '}';
run;

%let fname3=%mf_getuniquefileref();
proc http method='POST' in=&fname2 out=&fname3
    url="&base_uri/SASLogon/oauth/clients";
    headers "Content-Type"="application/json"
            "Authorization"="Bearer &access_token";
run;

/* show response */
%local err;
%let err=NONE;
data _null_;
  infile &fname3;
  input;
  if _infile_=:'{"err'!!'or":' then do;
    length message $32767;
    message=scan(_infile_,-2,'"');
    call symputx('err',message,'l');
  end;
run;
%if "&err" ne "NONE" %then %do;
  %put %str(ERR)OR: &err;
%end;

/* prepare url */
%if %index(%superq(grant_type),authorization_code) %then %do;
  data _null_;
    if symexist('_baseurl') then do;
      url=symget('_baseurl');
      if subpad(url,length(url)-9,9)='SASStudio'
        then url=substr(url,1,length(url)-11);
      else url="&systcpiphostname";
    end;
    else url="&systcpiphostname";
    call symputx('url',url);
  run;
%end;

%put Please provide the following details to the developer:;
%put ;
%put CLIENT_ID=&client_id;
%put CLIENT_SECRET=&client_secret;
%put GRANT_TYPE=&grant_type;
%put;
%if %index(%superq(grant_type),authorization_code) %then %do;
  /* cannot use base_uri here as it includes the protocol which may be incorrect
    externally */
  %put NOTE: Visit the link below and select 'openid' to get the grant code:;
  %put NOTE- ;
  %put NOTE- &url/SASLogon/oauth/authorize?client_id=&client_id%str(&)%trim(
    )response_type=code;
  %put NOTE- ;
%end;

data &outds;
  client_id=symget('client_id');
  client_secret=symget('client_secret');
  error=symget('err');
run;

data &outjson;
  infile &fname2;
  input;
  line=_infile_;
run;

/* clear refs */
filename &fname1 clear;
filename &fname2 clear;
filename &fname3 clear;
libname &libref clear;

%mend mv_registerclient;
/**
  @file mv_tokenauth.sas
  @brief Get initial Refresh and Access Tokens
  @details Before a Refresh Token can be obtained, the client must be
    registered by an administrator.  This can be done using the
    `mv_registerclient` macro, after which the user must visit a URL to get an
    additional code (if using oauth).

    That code (or username / password) is used here to get the Refresh Token
    (and an initial Access Token).  THIS MACRO CAN ONLY BE USED ONCE - further
    access tokens can be obtained using the `mv_gettokenrefresh` macro.

    Access tokens expire frequently (every 10 hours or so) whilst refresh tokens
    expire periodically (every month or so).  This is all configurable.

  Usage:

      filename mc url
        "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
      %inc mc;


      %mv_registerclient(outds=clientinfo)

      %mv_tokenauth(inds=clientinfo,code=LD39EpalOf)

    A great article for explaining all these steps is available here:

    https://blogs.sas.com/content/sgf/2019/01/25/authentication-to-sas-viya/

  @param inds= A dataset containing client_id, client_secret, and auth_code
  @param outds= A dataset containing access_token and refresh_token
  @param client_id= The client name
  @param client_secret= client secret
  @param grant_type= valid values are "password" or "authorization_code"
    (unquoted). The default is authorization_code.
  @param code= If grant_type=authorization_code then provide the necessary code
    here
  @param user= If grant_type=password then provide the username here
  @param pass= If grant_type=password then provide the password here
  @param access_token_var= The global macro variable to contain the access token
  @param refresh_token_var= The global macro variable to contain the refresh
    token
  @param base_uri= The Viya API server location

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_existds.sas

**/

%macro mv_tokenauth(inds=mv_registerclient
    ,outds=mv_tokenauth
    ,client_id=someclient
    ,client_secret=somesecret
    ,grant_type=authorization_code
    ,code=
    ,user=
    ,pass=
    ,access_token_var=ACCESS_TOKEN
    ,refresh_token_var=REFRESH_TOKEN
    ,base_uri=#NOTSET#
  );
%global &access_token_var &refresh_token_var;

%local fref1 fref2 libref;

/* test the validity of inputs */
%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password)
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%if %mf_existds(&inds) %then %do;
  data _null_;
    set &inds;
    call symputx('client_id',client_id,'l');
    call symputx('client_secret',client_secret,'l');
    if not missing(auth_code) then call symputx('code',auth_code,'l');
  run;
%end;

%mp_abort(iftrue=(&grant_type=authorization_code and %str(&code)=%str())
  ,mac=&sysmacroname
  ,msg=%str(Authorization code required)
)

%mp_abort(iftrue=(
  &grant_type=password and (%str(&user)=%str() or %str(&pass)=%str()))
  ,mac=&sysmacroname
  ,msg=%str(username / password required)
)

/* prepare appropriate grant type */
%let fref1=%mf_getuniquefileref();

data _null_;
  file &fref1;
  if "&grant_type"='authorization_code' then string=cats(
    'grant_type=authorization_code&code=',symget('code'));
  else string=cats('grant_type=password&username=',symget('user')
    ,'&password=',symget(pass));
  call symputx('grantstring',cats("'",string,"'"));
run;
/*data _null_;infile &fref1;input;put _infile_;run;*/

/**
  * Request access token
  */
%if &base_uri=#NOTSET# %then %let base_uri=%mf_getplatform(VIYARESTAPI);

%let fref2=%mf_getuniquefileref();
proc http method='POST' in=&grantstring out=&fref2
  url="&base_uri/SASLogon/oauth/token"
  WEBUSERNAME="&client_id"
  WEBPASSWORD="&client_secret"
  AUTH_BASIC;
  headers "Accept"="application/json"
          "Content-Type"="application/x-www-form-urlencoded";
run;
/*data _null_;infile &fref2;input;put _infile_;run;*/

/**
  * Extract access / refresh tokens
  */

%let libref=%mf_getuniquelibref();
libname &libref JSON fileref=&fref2;

/* extract the tokens */
data &outds;
  set &libref..root;
  call symputx("&access_token_var",access_token);
  call symputx("&refresh_token_var",refresh_token);
run;


libname &libref clear;
filename &fref1 clear;
filename &fref2 clear;

%mend mv_tokenauth;/**
  @file mv_tokenrefresh.sas
  @brief Get an additional access token using a refresh token
  @details Before an access token can be obtained, a refresh token is required
    For that, check out the `mv_tokenauth` macro.

  Usage:

      * prep work - register client, get refresh token, save it for later use ;
      %mv_registerclient(outds=client)
      %mv_tokenauth(inds=client,code=wKDZYTEPK6)
      data _null_;
      file "~/refresh.token";
      put "&refresh_token";
      run;

      * now do the things n stuff;
      data _null_;
        infile "~/refresh.token";
        input;
        call symputx('refresh_token',_infile_);
      run;
      %mv_tokenrefresh(client_id=&client
        ,client_secret=&secret
      )

  A great article for explaining all these steps is available here:

  https://blogs.sas.com/content/sgf/2019/01/25/authentication-to-sas-viya/

  @param inds= A dataset containing client_id and client_secret
  @param outds= A dataset containing access_token and refresh_token
  @param client_id= The client name (alternative to inds)
  @param client_secret= client secret (alternative to inds)
  @param grant_type= valid values are "password" or "authorization_code"
    (unquoted).  The default is authorization_code.
  @param user= If grant_type=password then provide the username here
  @param pass= If grant_type=password then provide the password here
  @param access_token_var= The global macro variable to contain the access token
  @param refresh_token_var= The global macro variable containing the refresh
    token

  @version VIYA V.03.04
  @author Allan Bowe, source: https://github.com/sasjs/core

  <h4> SAS Macros </h4>
  @li mp_abort.sas
  @li mf_getplatform.sas
  @li mf_getuniquefileref.sas
  @li mf_getuniquelibref.sas
  @li mf_existds.sas

**/

%macro mv_tokenrefresh(inds=mv_registerclient
    ,outds=mv_tokenrefresh
    ,client_id=someclient
    ,client_secret=somesecret
    ,grant_type=authorization_code
    ,user=
    ,pass=
    ,access_token_var=ACCESS_TOKEN
    ,refresh_token_var=REFRESH_TOKEN
  );
%global &access_token_var &refresh_token_var;
options noquotelenmax;

%local fref1 libref;

/* test the validity of inputs */
%mp_abort(iftrue=(&grant_type ne authorization_code and &grant_type ne password)
  ,mac=&sysmacroname
  ,msg=%str(Invalid value for grant_type: &grant_type)
)

%mp_abort(
  iftrue=(&grant_type=password and (%str(&user)=%str() or %str(&pass)=%str()))
  ,mac=&sysmacroname
  ,msg=%str(username / password required)
)

%if %mf_existds(&inds) %then %do;
  data _null_;
    set &inds;
    call symputx('client_id',client_id,'l');
    call symputx('client_secret',client_secret,'l');
    call symputx("&refresh_token_var",&refresh_token_var,'l');
  run;
%end;

%mp_abort(iftrue=(%str(&client_id)=%str() or %str(&client_secret)=%str())
  ,mac=&sysmacroname
  ,msg=%str(client / secret must both be provided)
)

/**
  * Request access token
  */
%local base_uri; /* location of rest apis */
%let base_uri=%mf_getplatform(VIYARESTAPI);

%let fref1=%mf_getuniquefileref();
proc http method='POST'
  in="grant_type=refresh_token%nrstr(&)refresh_token=&&&refresh_token_var"
  out=&fref1
  url="&base_uri/SASLogon/oauth/token"
  WEBUSERNAME="&client_id"
  WEBPASSWORD="&client_secret"
  AUTH_BASIC;
  headers "Accept"="application/json"
          "Content-Type"="application/x-www-form-urlencoded";
run;
/*data _null_;infile &fref1;input;put _infile_;run;*/

/**
  * Extract access / refresh tokens
  */

%let libref=%mf_getuniquelibref();
libname &libref JSON fileref=&fref1;

/* extract the token */
data &outds;
  set &libref..root;
  call symputx("&access_token_var",access_token);
  call symputx("&refresh_token_var",refresh_token);
run;


libname &libref clear;
filename &fref1 clear;

%mend mv_tokenrefresh;/**
  @file
  @brief Send data to/from the SAS Viya Job Execution Service
  @details This macro should be added to the start of each Job Execution
  Service, **immediately** followed by a call to:

        %mv_webout(FETCH)

    This will read all the input data and create same-named SAS datasets in the
    WORK library.  You can then insert your code, and send data back using the
    following syntax:

        data some datasets; * make some data ;
          retain some columns;
        run;

        %mv_webout(OPEN)
        %mv_webout(ARR,some)  * Array format, fast, suitable for large tables ;
        %mv_webout(OBJ,datasets) * Object format, easier to work with ;
        %mv_webout(CLOSE)


  @param action Either OPEN, ARR, OBJ or CLOSE
  @param ds The dataset to send back to the frontend
  @param _webout= fileref for returning the json
  @param fref=(_mvwtemp) Temp fileref to which to write the output
  @param dslabel= value to use instead of the real name for sending to JSON
  @param fmt=(Y) change to N to strip formats from output
  @param stream=(Y) Change to N if not streaming to _webout

  <h4> SAS Macros </h4>
  @li mp_jsonout.sas
  @li mf_getuser.sas

  @version Viya 3.3
  @author Allan Bowe, source: https://github.com/sasjs/core

**/
%macro mv_webout(action,ds,fref=_mvwtemp,dslabel=,fmt=Y,stream=Y);
%global _webin_file_count _webin_fileuri _debug _omittextlog _webin_name
  sasjs_tables SYS_JES_JOB_URI;
%if %index("&_debug",log) %then %let _debug=131;

%local i tempds;
%let action=%upcase(&action);

%if &action=FETCH %then %do;
  %if %upcase(&_omittextlog)=FALSE or %str(&_debug) ge 131 %then %do;
    options mprint notes mprintnest;
  %end;

  %if not %symexist(_webin_fileuri1) %then %do;
    %let _webin_file_count=%eval(&_webin_file_count+0);
    %let _webin_fileuri1=&_webin_fileuri;
    %let _webin_name1=&_webin_name;
  %end;

  /* if the sasjs_tables param is passed, we expect param based upload */
  %if %length(&sasjs_tables.XX)>2 %then %do;
    filename _sasjs "%sysfunc(pathname(work))/sasjs.lua";
    data _null_;
      file _sasjs;
      put 's=sas.symget("sasjs_tables")';
      put 'if(s:sub(1,7) == "%nrstr(")';
      put 'then';
      put ' tablist=s:sub(8,s:len()-1)';
      put 'else';
      put ' tablist=s';
      put 'end';
      put 'for i = 1,sas.countw(tablist) ';
      put 'do ';
      put '  tab=sas.scan(tablist,i)';
      put '  sasdata=""';
      put '  if (sas.symexist("sasjs"..i.."data0")==0)';
      put '  then';
      /* TODO - condense this logic */
      put '    s=sas.symget("sasjs"..i.."data")';
      put '    if(s:sub(1,7) == "%nrstr(")';
      put '    then';
      put '      sasdata=s:sub(8,s:len()-1)';
      put '    else';
      put '      sasdata=s';
      put '    end';
      put '  else';
      put '    for d = 1, sas.symget("sasjs"..i.."data0")';
      put '    do';
      put '      s=sas.symget("sasjs"..i.."data"..d)';
      put '      if(s:sub(1,7) == "%nrstr(")';
      put '      then';
      put '        sasdata=sasdata..s:sub(8,s:len()-1)';
      put '      else';
      put '        sasdata=sasdata..s';
      put '      end';
      put '    end';
      put '  end';
      put '  file = io.open(sas.pathname("work").."/"..tab..".csv", "a")';
      put '  io.output(file)';
      put '  io.write(sasdata)';
      put '  io.close(file)';
      put 'end';
    run;
    %inc _sasjs;

    /* now read in the data */
    %do i=1 %to %sysfunc(countw(&sasjs_tables));
      %local table; %let table=%scan(&sasjs_tables,&i);
      data _null_;
        infile "%sysfunc(pathname(work))/&table..csv" termstr=crlf ;
        input;
        if _n_=1 then call symputx('input_statement',_infile_);
        list;
      data &table;
        infile "%sysfunc(pathname(work))/&table..csv" firstobs=2 dsd
          termstr=crlf;
        input &input_statement;
      run;
    %end;
  %end;
  %else %do i=1 %to &_webin_file_count;
    /* read in any files that are sent */
    /* this part needs refactoring for wide files */
    filename indata filesrvc "&&_webin_fileuri&i" lrecl=999999;
    data _null_;
      infile indata termstr=crlf lrecl=32767;
      input;
      if _n_=1 then call symputx('input_statement',_infile_);
      %if %str(&_debug) ge 131 %then %do;
        if _n_<20 then putlog _infile_;
        else stop;
      %end;
      %else %do;
        stop;
      %end;
    run;
    data &&_webin_name&i;
      infile indata firstobs=2 dsd termstr=crlf ;
      input &input_statement;
    run;
    %let sasjs_tables=&sasjs_tables &&_webin_name&i;
  %end;
%end;
%else %if &action=OPEN %then %do;
  /* setup webout */
  OPTIONS NOBOMFILE;
  %if "X&SYS_JES_JOB_URI.X"="XX" %then %do;
    filename _webout temp lrecl=999999 mod;
  %end;
  %else %do;
    filename _webout filesrvc parenturi="&SYS_JES_JOB_URI"
      name="_webout.json" lrecl=999999 mod;
  %end;

  /* setup temp ref */
  %if %upcase(&fref) ne _WEBOUT %then %do;
    filename &fref temp lrecl=999999 permission='A::u::rwx,A::g::rw-,A::o::---'
      mod;
  %end;

  /* setup json */
  data _null_;file &fref;
    put '{"START_DTTM" : "' "%sysfunc(datetime(),datetime20.3)" '"';
  run;
%end;
%else %if &action=ARR or &action=OBJ %then %do;
    %mp_jsonout(&action,&ds,dslabel=&dslabel,fmt=&fmt
      ,jref=&fref,engine=DATASTEP,dbg=%str(&_debug)
    )
%end;
%else %if &action=CLOSE %then %do;
  %if %str(&_debug) ge 131 %then %do;
    /* send back first 10 records of each work table for debugging */
    options obs=10;
    data;run;%let tempds=%scan(&syslast,2,.);
    ods output Members=&tempds;
    proc datasets library=WORK memtype=data;
    %local wtcnt;%let wtcnt=0;
    data _null_;
      set &tempds;
      if not (upcase(name) =:"DATA"); /* ignore temp datasets */
      i+1;
      call symputx('wt'!!left(i),name);
      call symputx('wtcnt',i);
    data _null_; file &fref mod; put ",""WORK"":{";
    %do i=1 %to &wtcnt;
      %let wt=&&wt&i;
      proc contents noprint data=&wt
        out=_data_ (keep=name type length format:);
      run;%let tempds=%scan(&syslast,2,.);
      data _null_; file &fref mod;
        dsid=open("WORK.&wt",'is');
        nlobs=attrn(dsid,'NLOBS');
        nvars=attrn(dsid,'NVARS');
        rc=close(dsid);
        if &i>1 then put ','@;
        put " ""&wt"" : {";
        put '"nlobs":' nlobs;
        put ',"nvars":' nvars;
      %mp_jsonout(OBJ,&tempds,jref=&fref,dslabel=colattrs,engine=DATASTEP)
      %mp_jsonout(OBJ,&wt,jref=&fref,dslabel=first10rows,engine=DATASTEP)
      data _null_; file &fref mod;put "}";
    %end;
    data _null_; file &fref mod;put "}";run;
  %end;

  /* close off json */
  data _null_;file &fref mod;
    _PROGRAM=quote(trim(resolve(symget('_PROGRAM'))));
    put ",""SYSUSERID"" : ""&sysuserid"" ";
    put ",""MF_GETUSER"" : ""%mf_getuser()"" ";
    SYS_JES_JOB_URI=quote(trim(resolve(symget('SYS_JES_JOB_URI'))));
    put ',"SYS_JES_JOB_URI" : ' SYS_JES_JOB_URI ;
    put ",""SYSJOBID"" : ""&sysjobid"" ";
    put ",""_DEBUG"" : ""&_debug"" ";
    put ',"_PROGRAM" : ' _PROGRAM ;
    put ",""SYSCC"" : ""&syscc"" ";
    put ",""SYSERRORTEXT"" : ""&syserrortext"" ";
    put ",""SYSHOSTNAME"" : ""&syshostname"" ";
    put ",""SYSSCPL"" : ""&sysscpl"" ";
    put ",""SYSSITE"" : ""&syssite"" ";
    sysvlong=quote(trim(symget('sysvlong')));
    put ',"SYSVLONG" : ' sysvlong;
    put ",""SYSWARNINGTEXT"" : ""&syswarningtext"" ";
    put ',"END_DTTM" : "' "%sysfunc(datetime(),datetime20.3)" '" ';
    put "}";

  %if %upcase(&fref) ne _WEBOUT and &stream=Y %then %do;
    data _null_; rc=fcopy("&fref","_webout");run;
  %end;

%end;

%mend mv_webout;
/**
  @file ml_gsubfile.sas
  @brief Compiles the gsubfile.lua lua file
  @details Writes gsubfile.lua to the work directory
  and then includes it.
  Usage:

      %ml_gsubfile()

**/

%macro ml_gsubfile();
data _null_;
  file "%sysfunc(pathname(work))/ml_gsubfile.lua";
  put 'local fpath, outpath, file, fcontent ';
  put ' ';
  put '-- configure in / out paths ';
  put 'fpath = sas.symget("file") ';
  put 'outpath = sas.symget("outfile") ';
  put 'if ( outpath == 0 ) ';
  put 'then ';
  put '   outpath=fpath ';
  put 'end ';
  put ' ';
  put '-- open file and perform the substitution ';
  put 'file = io.open(fpath,"r") ';
  put 'fcontent = file:read("*all") ';
  put 'file:close() ';
  put 'fcontent = string.gsub( ';
  put '  fcontent, ';
  put '  sas.symget(sas.symget("patternvar")), ';
  put '  sas.symget(sas.symget("replacevar")) ';
  put ') ';
  put ' ';
  put '-- write the file back out ';
  put 'file = io.open(outpath, "w+") ';
  put 'io.output(file) ';
  put 'io.write(fcontent) ';
  put 'io.close(file) ';
run;

%inc "%sysfunc(pathname(work))/ml_gsubfile.lua" /source2;

%mend ml_gsubfile;
/**
  @file ml_json.sas
  @brief Compiles the json.lua lua file
  @details Writes json.lua to the work directory
  and then includes it.
  Usage:

      %ml_json()

**/

%macro ml_json();
data _null_;
  file "%sysfunc(pathname(work))/ml_json.lua";
  put '-- NOTE - THE COPYRIGHT BELOW IS IN RELATION TO THE JSON.LUA FILE ONLY ';
  put '-- THIS FILE STARTS ON THE NEXT LINE AND WILL FINISH WITH "JSON.LUA ENDS HERE" ';
  put '-- ';
  put '-- json.lua ';
  put '-- ';
  put '-- Copyright (c) 2019 rxi ';
  put '-- ';
  put '-- Permission is hereby granted, free of charge, to any person obtaining a copy of ';
  put '-- this software and associated documentation files (the "Software"), to deal in ';
  put '-- the Software without restriction, including without limitation the rights to ';
  put '-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies ';
  put '-- of the Software, and to permit persons to whom the Software is furnished to do ';
  put '-- so, subject to the following conditions: ';
  put '-- ';
  put '-- The above copyright notice and this permission notice shall be included in all ';
  put '-- copies or substantial portions of the Software. ';
  put '-- ';
  put '-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR ';
  put '-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, ';
  put '-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE ';
  put '-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER ';
  put '-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, ';
  put '-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE ';
  put '-- SOFTWARE. ';
  put '-- ';
  put ' ';
  put 'json = { _version = "0.1.2" } ';
  put ' ';
  put '------------------------------------------------------------------------------- ';
  put '-- Encode ';
  put '------------------------------------------------------------------------------- ';
  put ' ';
  put 'local encode ';
  put ' ';
  put 'local escape_char_map = { ';
  put '  [ "\\" ] = "\\\\", ';
  put '  [ "\"" ] = "\\\"", ';
  put '  [ "\b" ] = "\\b", ';
  put '  [ "\f" ] = "\\f", ';
  put '  [ "\n" ] = "\\n", ';
  put '  [ "\r" ] = "\\r", ';
  put '  [ "\t" ] = "\\t", ';
  put '} ';
  put ' ';
  put 'local escape_char_map_inv = { [ "\\/" ] = "/" } ';
  put 'for k, v in pairs(escape_char_map) do ';
  put '  escape_char_map_inv[v] = k ';
  put 'end ';
  put ' ';
  put 'local function escape_char(c) ';
  put '  return escape_char_map[c] or string.format("\\u%04x", c:byte()) ';
  put 'end ';
  put ' ';
  put 'local function encode_nil(val) ';
  put '  return "null" ';
  put 'end ';
  put ' ';
  put 'local function encode_table(val, stack) ';
  put '  local res = {} ';
  put '  stack = stack or {} ';
  put ' ';
  put '  -- Circular reference? ';
  put '  if stack[val] then error("circular reference") end ';
  put ' ';
  put '  stack[val] = true ';
  put ' ';
  put '  if rawget(val, 1) ~= nil or next(val) == nil then ';
  put '    -- Treat as array -- check keys are valid and it is not sparse ';
  put '    local n = 0 ';
  put '    for k in pairs(val) do ';
  put '      if type(k) ~= "number" then ';
  put '        error("invalid table: mixed or invalid key types") ';
  put '      end ';
  put '      n = n + 1 ';
  put '    end ';
  put '    if n ~= #val then ';
  put '      error("invalid table: sparse array") ';
  put '    end ';
  put '    -- Encode ';
  put '    for i, v in ipairs(val) do ';
  put '      table.insert(res, encode(v, stack)) ';
  put '    end ';
  put '    stack[val] = nil ';
  put '    return "[" .. table.concat(res, ",") .. "]" ';
  put '  else ';
  put '    -- Treat as an object ';
  put '    for k, v in pairs(val) do ';
  put '      if type(k) ~= "string" then ';
  put '        error("invalid table: mixed or invalid key types") ';
  put '      end ';
  put '      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack)) ';
  put '    end ';
  put '    stack[val] = nil ';
  put '    return "{" .. table.concat(res, ",") .. "}" ';
  put '  end ';
  put 'end ';
  put ' ';
  put 'local function encode_string(val) ';
  put '  return ''"'' .. val:gsub(''[%z\1-\31\\"]'', escape_char) .. ''"'' ';
  put 'end ';
  put ' ';
  put 'local function encode_number(val) ';
  put '  -- Check for NaN, -inf and inf ';
  put '  if val ~= val or val <= -math.huge or val >= math.huge then ';
  put '    error("unexpected number value ''" .. tostring(val) .. "''") ';
  put '  end ';
  put '  return string.format("%.14g", val) ';
  put 'end ';
  put ' ';
  put 'local type_func_map = { ';
  put '  [ "nil"     ] = encode_nil, ';
  put '  [ "table"   ] = encode_table, ';
  put '  [ "string"  ] = encode_string, ';
  put '  [ "number"  ] = encode_number, ';
  put '  [ "boolean" ] = tostring, ';
  put '} ';
  put ' ';
  put 'encode = function(val, stack) ';
  put '  local t = type(val) ';
  put '  local f = type_func_map[t] ';
  put '  if f then ';
  put '    return f(val, stack) ';
  put '  end ';
  put '  error("unexpected type ''" .. t .. "''") ';
  put 'end ';
  put ' ';
  put 'function json.encode(val) ';
  put '  return ( encode(val) ) ';
  put 'end ';
  put ' ';
  put '------------------------------------------------------------------------------- ';
  put '-- Decode ';
  put '------------------------------------------------------------------------------- ';
  put 'local parse ';
  put 'local function create_set(...) ';
  put '  local res = {} ';
  put '  for i = 1, select("#", ...) do ';
  put '    res[ select(i, ...) ] = true ';
  put '  end ';
  put '  return res ';
  put 'end ';
  put ' ';
  put 'local space_chars   = create_set(" ", "\t", "\r", "\n") ';
  put 'local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",") ';
  put 'local escape_chars  = create_set("\\", "/", ''"'', "b", "f", "n", "r", "t", "u") ';
  put 'local literals      = create_set("true", "false", "null") ';
  put ' ';
  put 'local literal_map = { ';
  put '  [ "true"  ] = true, ';
  put '  [ "false" ] = false, ';
  put '  [ "null"  ] = nil, ';
  put '} ';
  put ' ';
  put 'local function next_char(str, idx, set, negate) ';
  put '  for i = idx, #str do ';
  put '    if set[str:sub(i, i)] ~= negate then ';
  put '      return i ';
  put '    end ';
  put '  end ';
  put '  return #str + 1 ';
  put 'end ';
  put ' ';
  put 'local function decode_error(str, idx, msg) ';
  put '  local line_count = 1 ';
  put '  local col_count = 1 ';
  put '  for i = 1, idx - 1 do ';
  put '    col_count = col_count + 1 ';
  put '    if str:sub(i, i) == "\n" then ';
  put '      line_count = line_count + 1 ';
  put '      col_count = 1 ';
  put '    end ';
  put '  end ';
  put '  error( string.format("%s at line %d col %d", msg, line_count, col_count) ) ';
  put 'end ';
  put ' ';
  put 'local function codepoint_to_utf8(n) ';
  put '  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa ';
  put '  local f = math.floor ';
  put '  if n <= 0x7f then ';
  put '    return string.char(n) ';
  put '  elseif n <= 0x7ff then ';
  put '    return string.char(f(n / 64) + 192, n % 64 + 128) ';
  put '  elseif n <= 0xffff then ';
  put '    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128) ';
  put '  elseif n <= 0x10ffff then ';
  put '    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, ';
  put '                       f(n % 4096 / 64) + 128, n % 64 + 128) ';
  put '  end ';
  put '  error( string.format("invalid unicode codepoint ''%x''", n) ) ';
  put 'end ';
  put ' ';
  put 'local function parse_unicode_escape(s) ';
  put '  local n1 = tonumber( s:sub(3, 6),  16 ) ';
  put '  local n2 = tonumber( s:sub(9, 12), 16 ) ';
  put '  -- Surrogate pair? ';
  put '  if n2 then ';
  put '    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000) ';
  put '  else ';
  put '    return codepoint_to_utf8(n1) ';
  put '  end ';
  put 'end ';
  put ' ';
  put 'local function parse_string(str, i) ';
  put '  local has_unicode_escape = false ';
  put '  local has_surrogate_escape = false ';
  put '  local has_escape = false ';
  put '  local last ';
  put '  for j = i + 1, #str do ';
  put '    local x = str:byte(j) ';
  put '    if x < 32 then ';
  put '      decode_error(str, j, "control character in string") ';
  put '    end ';
  put '    if last == 92 then -- "\\" (escape char) ';
  put '      if x == 117 then -- "u" (unicode escape sequence) ';
  put '        local hex = str:sub(j + 1, j + 5) ';
  put '        if not hex:find("%x%x%x%x") then ';
  put '          decode_error(str, j, "invalid unicode escape in string") ';
  put '        end ';
  put '        if hex:find("^[dD][89aAbB]") then ';
  put '          has_surrogate_escape = true ';
  put '        else ';
  put '          has_unicode_escape = true ';
  put '        end ';
  put '      else ';
  put '        local c = string.char(x) ';
  put '        if not escape_chars[c] then ';
  put '          decode_error(str, j, "invalid escape char ''" .. c .. "'' in string") ';
  put '        end ';
  put '        has_escape = true ';
  put '      end ';
  put '      last = nil ';
  put '    elseif x == 34 then -- ''"'' (end of string) ';
  put '      local s = str:sub(i + 1, j - 1) ';
  put '      if has_surrogate_escape then ';
  put '        s = s:gsub("\\u[dD][89aAbB]..\\u....", parse_unicode_escape) ';
  put '      end ';
  put '      if has_unicode_escape then ';
  put '        s = s:gsub("\\u....", parse_unicode_escape) ';
  put '      end ';
  put '      if has_escape then ';
  put '        s = s:gsub("\\.", escape_char_map_inv) ';
  put '      end ';
  put '      return s, j + 1 ';
  put '    else ';
  put '      last = x ';
  put '    end ';
  put '  end ';
  put '  decode_error(str, i, "expected closing quote for string") ';
  put 'end ';
  put ' ';
  put 'local function parse_number(str, i) ';
  put '  local x = next_char(str, i, delim_chars) ';
  put '  local s = str:sub(i, x - 1) ';
  put '  local n = tonumber(s) ';
  put '  if not n then ';
  put '    decode_error(str, i, "invalid number ''" .. s .. "''") ';
  put '  end ';
  put '  return n, x ';
  put 'end ';
  put ' ';
  put 'local function parse_literal(str, i) ';
  put '  local x = next_char(str, i, delim_chars) ';
  put '  local word = str:sub(i, x - 1) ';
  put '  if not literals[word] then ';
  put '    decode_error(str, i, "invalid literal ''" .. word .. "''") ';
  put '  end ';
  put '  return literal_map[word], x ';
  put 'end ';
  put ' ';
  put 'local function parse_array(str, i) ';
  put '  local res = {} ';
  put '  local n = 1 ';
  put '  i = i + 1 ';
  put '  while 1 do ';
  put '    local x ';
  put '    i = next_char(str, i, space_chars, true) ';
  put '    -- Empty / end of array? ';
  put '    if str:sub(i, i) == "]" then ';
  put '      i = i + 1 ';
  put '      break ';
  put '    end ';
  put '    -- Read token ';
  put '    x, i = parse(str, i) ';
  put '    res[n] = x ';
  put '    n = n + 1 ';
  put '    -- Next token ';
  put '    i = next_char(str, i, space_chars, true) ';
  put '    local chr = str:sub(i, i) ';
  put '    i = i + 1 ';
  put '    if chr == "]" then break end ';
  put '    if chr ~= "," then decode_error(str, i, "expected '']'' or '',''") end ';
  put '  end ';
  put '  return res, i ';
  put 'end ';
  put ' ';
  put 'local function parse_object(str, i) ';
  put '  local res = {} ';
  put '  i = i + 1 ';
  put '  while 1 do ';
  put '    local key, val ';
  put '    i = next_char(str, i, space_chars, true) ';
  put '    -- Empty / end of object? ';
  put '    if str:sub(i, i) == "}" then ';
  put '      i = i + 1 ';
  put '      break ';
  put '    end ';
  put '    -- Read key ';
  put '    if str:sub(i, i) ~= ''"'' then ';
  put '      decode_error(str, i, "expected string for key") ';
  put '    end ';
  put '    key, i = parse(str, i) ';
  put '    -- Read '':'' delimiter ';
  put '    i = next_char(str, i, space_chars, true) ';
  put '    if str:sub(i, i) ~= ":" then ';
  put '      decode_error(str, i, "expected '':'' after key") ';
  put '    end ';
  put '    i = next_char(str, i + 1, space_chars, true) ';
  put '    -- Read value ';
  put '    val, i = parse(str, i) ';
  put '    -- Set ';
  put '    res[key] = val ';
  put '    -- Next token ';
  put '    i = next_char(str, i, space_chars, true) ';
  put '    local chr = str:sub(i, i) ';
  put '    i = i + 1 ';
  put '    if chr == "}" then break end ';
  put '    if chr ~= "," then decode_error(str, i, "expected ''}'' or '',''") end ';
  put '  end ';
  put '  return res, i ';
  put 'end ';
  put ' ';
  put 'local char_func_map = { ';
  put '  [ ''"'' ] = parse_string, ';
  put '  [ "0" ] = parse_number, ';
  put '  [ "1" ] = parse_number, ';
  put '  [ "2" ] = parse_number, ';
  put '  [ "3" ] = parse_number, ';
  put '  [ "4" ] = parse_number, ';
  put '  [ "5" ] = parse_number, ';
  put '  [ "6" ] = parse_number, ';
  put '  [ "7" ] = parse_number, ';
  put '  [ "8" ] = parse_number, ';
  put '  [ "9" ] = parse_number, ';
  put '  [ "-" ] = parse_number, ';
  put '  [ "t" ] = parse_literal, ';
  put '  [ "f" ] = parse_literal, ';
  put '  [ "n" ] = parse_literal, ';
  put '  [ "[" ] = parse_array, ';
  put '  [ "{" ] = parse_object, ';
  put '} ';
  put ' ';
  put 'parse = function(str, idx) ';
  put '  local chr = str:sub(idx, idx) ';
  put '  local f = char_func_map[chr] ';
  put '  if f then ';
  put '    return f(str, idx) ';
  put '  end ';
  put '  decode_error(str, idx, "unexpected character ''" .. chr .. "''") ';
  put 'end ';
  put ' ';
  put 'function json.decode(str) ';
  put '  if type(str) ~= "string" then ';
  put '    error("expected argument of type string, got " .. type(str)) ';
  put '  end ';
  put '  local res, idx = parse(str, next_char(str, 1, space_chars, true)) ';
  put '  idx = next_char(str, idx, space_chars, true) ';
  put '  if idx <= #str then ';
  put '    decode_error(str, idx, "trailing garbage") ';
  put '  end ';
  put '  return res ';
  put 'end ';
  put ' ';
  put 'return json ';
  put ' ';
  put '-- JSON.LUA ENDS HERE ';
run;

%inc "%sysfunc(pathname(work))/ml_json.lua" /source2;

%mend ml_json;
/**
  @file
  @brief Provides a replacement for the stpsrv_header function
  @details The stpsrv_header is normally a built-in function, used to set the
  headers for SAS 9 Stored Processes as documented here:
  https://go.documentation.sas.com/doc/en/itechcdc/9.4/stpug/srvhead.htm

  The purpose of this custom function is to provide a replacement when running
  similar code as a web service against
  [sasjs/server](https://github.com/sasjs/server).  It operates by creating a
  text file with the headers.  The location of this text file is determined by
  a macro variable (`sasjs_stpsrv_header_loc`) which needs to be injected into
  each service by the calling process, eg:

      %let sasjs_stpsrv_header_loc = C:/temp/some_uuid/stpsrv_header.txt;

  Note - the function works by appending headers to the file.  If multiple same-
  named headers are provided, they will all be appended - the calling process
  needs to pick up the last one.  This will mean removing the attribute if the
  final record has an empty value.

  The function takes the following (positional) parameters:

  | PARAMETER | DESCRIPTION |
  |------------|-------------|
  | name $  | name of the header attribute to create|
  | value  $  | value of the header attribute|

  It returns 0 if successful, or -1 if an error occured.

  Usage:

      %let sasjs_stpsrv_header_loc=%sysfunc(pathname(work))/stpsrv_header.txt;

      %mcf_stpsrv_header(wrap=YES, insert_cmplib=YES)

      data _null_;
        rc=stpsrv_header('Content-type','application/text');
        rc=stpsrv_header('Content-disposition',"attachment; filename=file.txt");
      run;

      data _null_;
        infile "&sasjs_stpsrv_header_loc";
        input;
        putlog _infile_;
      run;


  @param [out] wrap= (NO) Choose YES to add the proc fcmp wrapper.
  @param [out] insert_cmplib= (NO) Choose YES to insert the package into the
    CMPLIB reference.
  @param [out] lib= (work) The output library in which to create the catalog.
  @param [out] cat= (sasjs) The output catalog in which to create the package.
  @param [out] pkg= (utils) The output package in which to create the function.
    Uses a 3 part format:  libref.catalog.package

  <h4> SAS Macros </h4>
  @li mf_existfunction.sas

**/

%macro mcf_stpsrv_header(wrap=NO
  ,insert_cmplib=NO
  ,lib=WORK
  ,cat=SASJS
  ,pkg=UTILS
)/*/STORE SOURCE*/;

%if %mf_existfunction(stpsrv_header)=1 %then %return;

%if &wrap=YES  %then %do;
  proc fcmp outcat=&lib..&cat..&pkg;
%end;

function stpsrv_header(name $, value $);
  length loc $128 val $512;
  loc=symget('sasjs_stpsrv_header_loc');
  val=trim(name)!!': '!!value;
  length fref $8;
  rc=filename(fref,loc);
  if (rc ne 0) then return( -1 );
  fid = fopen(fref,'a');
  if (fid = 0) then return( -1 );
  rc=fput(fid, val);
  rc=fwrite(fid);
  rc=fclose(fid);
  rc=filename(fref);
  return(0);
endsub;

%if &wrap=YES %then %do;
  quit;
%end;

%if &insert_cmplib=YES %then %do;
  options insert=(CMPLIB=(&lib..&cat));
%end;

%mend mcf_stpsrv_header;/**
  @file
  @brief Adds a string to a file
  @details Creates an fcmp function for appending a string to an external file.
  If the file does not exist, it is created.

  The function itself takes the following (positional) parameters:

  | PARAMETER | DESCRIPTION |
  |------------|-------------|
  | filepath $  | full path to the file|
  | string  $  | string to add to the file |
  | mode $     | mode of the output - either APPEND (default) or CREATE |

  It returns 0 if successful, or -1 if an error occured.

  Usage:

      %mcf_string2file(wrap=YES, insert_cmplib=YES)

      data _null_;
        rc=mcf_string2file(
          "%sysfunc(pathname(work))/newfile.txt"
          , "This is a test"
          , "CREATE");
      run;

      data _null_;
        infile "%sysfunc(pathname(work))/newfile.txt";
        input;
        putlog _infile_;
      run;

  @param [out] wrap= (NO) Choose YES to add the proc fcmp wrapper.
  @param [out] insert_cmplib= (NO) Choose YES to insert the package into the
    CMPLIB reference.
  @param [out] lib= (work) The output library in which to create the catalog.
  @param [out] cat= (sasjs) The output catalog in which to create the package.
  @param [out] pkg= (utils) The output package in which to create the function.
    Uses a 3 part format:  libref.catalog.package

**/

%macro mcf_string2file(wrap=NO
  ,insert_cmplib=NO
  ,lib=WORK
  ,cat=SASJS
  ,pkg=UTILS
)/*/STORE SOURCE*/;

%if &wrap=YES  %then %do;
  proc fcmp outcat=&lib..&cat..&pkg;
%end;

function mcf_string2file(filepath $, string $, mode $);
  if mode='APPEND' then fmode='a';
  else fmode='o';
  length fref $8;
  rc=filename(fref,filepath);
  if (rc ne 0) then return( -1 );
  fid = fopen(fref,fmode);
  if (fid = 0) then return( -1 );
  rc=fput(fid, string);
  rc=fwrite(fid);
  rc=fclose(fid);
  rc=filename(fref);
  return(0);
endsub;


%if &wrap=YES %then %do;
  quit;
%end;

%if &insert_cmplib=YES %then %do;
  options insert=(CMPLIB=(&lib..&cat));
%end;

%mend mcf_string2file;