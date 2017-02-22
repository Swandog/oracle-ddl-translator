use v6;
use Grammar::Tracer;

grammar TranslateOracleDDL::Grammar {
    token TOP {
        <sql-statement>+
    }

    token string-to-end-of-line {
        \V+
    }

    proto rule sql-statement { * }

    token sql-statement:sym<REM> {
        'REM' [ \h+ <string-to-end-of-line> ]? \v?
    }

    token sql-statement:sym<PROMPT> {
        'PROMPT' [ \h+ <string-to-end-of-line> ]? \v?
    }

    token sql-statement:sym<empty-line> {  # happens between statements
        \v+
    }

    token identifier { \w+ }
    token bigint { \d+ }
    token integer { \d+ }
    token entity-name {
        <identifier>** 1..3 % '.' # accepts "name" or "table.name" or "schema.table.name"
    }

    proto token value { * }
    token value:sym<number-value> { \d+ }
    token value:sym<string-value> {
        "'"
        [ <-[']>+:
            | "''"
        ]*
        "'"
    }
    token value:sym<systimestamp-function> { 'systimestamp' }

    proto token entity-type { * }
    token entity-type:sym<TABLE> { <sym> }
    token entity-type:sym<COLUMN> { <sym> }

    rule sql-statement:sym<COMMENT-ON> {
        'COMMENT' 'ON' <entity-type> <entity-name> 'IS' <value> ';'
    }

    token sql-statement:sym<CREATE-SEQUENCE> {
        'CREATE SEQUENCE' <ws> <entity-name> [ <ws> <create-sequence-clause> ]* <ws>*? ';'
    }

    proto token create-sequence-clause { * }
    token create-sequence-clause:sym<START-WITH>     { 'START WITH' <ws> <bigint> }
    token create-sequence-clause:sym<INCREMENT-BY>   { 'INCREMENT BY' <ws> <bigint> }
    token create-sequence-clause:sym<MINVALUE>       { 'MINVALUE' <ws> <bigint> }
    token create-sequence-clause:sym<NOMINVALUE>     { 'NOMINVALUE' }
    token create-sequence-clause:sym<MAXVALUE>       { 'MAXVALUE' <ws> <bigint> }
    token create-sequence-clause:sym<NOMAXVALUE>     { 'NOMAXVALUE' }
    token create-sequence-clause:sym<CACHE>          { 'CACHE' <ws> <bigint> }
    token create-sequence-clause:sym<NOCACHE>        { 'NOCACHE' }
    token create-sequence-clause:sym<CYCLE>          { 'CYCLE' }
    token create-sequence-clause:sym<NOCYCLE>        { 'NOCYCLE' }
    token create-sequence-clause:sym<ORDER>          { 'ORDER' }
    token create-sequence-clause:sym<NOORDER>        { 'NOORDER' }

    rule sql-statement:sym<CREATE-TABLE> {
        'CREATE TABLE'
        <entity-name>
        '('
            <create-table-column-def>+? % ','
            [ ',' <table-constraint-def> ]*
        ')'
        <create-table-extra-oracle-stuff>*
        ';'
    }

    rule create-table-column-def { <identifier> <column-type> <create-table-column-constraint>* }

    rule create-table-extra-oracle-stuff {
        [ 'ORGANIZATION' [ 'HEAP' | 'INDEX' ]? ]
        | 'MONITORING'
        | 'OVERFLOW'
    }

    proto rule column-type { * }
    rule column-type:sym<VARCHAR2>          { 'VARCHAR2'    [ '(' <integer> ')' ]? }
    rule column-type:sym<NUMBER-with-scale> { 'NUMBER' '(' <integer> ',' <integer> ')' }
    rule column-type:sym<NUMBER-with-prec>  { 'NUMBER' '(' <integer> ')' }
    rule column-type:sym<NUMBER>            { 'NUMBER' }
    rule column-type:sym<FLOAT>             { 'FLOAT' }
    rule column-type:sym<INTEGER>           { 'INTEGER' }
    rule column-type:sym<DATE>              { 'DATE' }
    rule column-type:sym<TIMESTAMP>         { 'TIMESTAMP' '(' <integer> ')' }
    rule column-type:sym<CHAR>              { 'CHAR' '(' <integer> ')' }
    rule column-type:sym<BLOB>              { 'BLOB' }
    rule column-type:sym<CLOB>              { 'CLOB' }
    rule column-type:sym<LONG>              { 'LONG' }
    rule column-type:sym<RAW>               { 'RAW' '(' <integer> ')' }

    proto rule create-table-column-constraint { * }
    rule create-table-column-constraint:sym<NOT-NULL> { 'NOT NULL' }
    rule create-table-column-constraint:sym<PRIMARY-KEY> { 'PRIMARY KEY' }

    rule create-table-column-constraint:sym<DEFAULT> { 'DEFAULT' <value> }

    rule table-constraint-def { 'CONSTRAINT' <identifier> <table-constraint> }

    proto rule table-constraint { * }
    rule table-constraint:sym<PRIMARY-KEY> { 'PRIMARY' 'KEY' '(' [ <identifier> + % ',' ] ')' }

    rule sql-statement:sym<SELECT> {
        'SELECT'
        <select-column-list>
        ['FROM'|'from'] <rest-of-select>
    }

    rule select-column-list { <select-column-def>+ % ',' }

    proto rule select-column-def { * }
    rule select-column-def:sym<COLUMN-NAME> { <identifier> }
    rule select-column-def:sym<QUOTED-COLUMN-NAME> { '"' <identifier> '"' }

    rule rest-of-select { [ <string-to-end-of-line> ]? }

    # Views

    rule sql-statement:sym<VIEW> {
        #{say "Starting VIEW consumption ";
        # say $¢.orig().substr($¢.pos()) }
        'CREATE OR REPLACE VIEW'
        <view-table-def>
        '(' <select-column-list> ')'
        'AS'
        #{say "AS looks like $3 " ~ $3.postmatch }
        <sql-statement>
    }

    rule view-table-def { <entity-name> }
    
}

