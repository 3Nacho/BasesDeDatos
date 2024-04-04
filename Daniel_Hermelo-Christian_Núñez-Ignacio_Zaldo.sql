--Repositorio: https://github.com/3Nacho/BasesDeDatos
-- Autores:
-- Christian Núñez Duque
-- Daniel Hermelo Puente
-- Ignacio Zaldo González

drop table clientes cascade constraints;
drop table abonos   cascade constraints;
drop table eventos  cascade constraints;
drop table reservas	cascade constraints;

drop sequence seq_abonos;
drop sequence seq_eventos;
drop sequence seq_reservas;


-- Creación de tablas y secuencias

create table clientes(
	NIF	varchar(9) primary key,
	nombre	varchar(20) not null,
	ape1	varchar(20) not null,
	ape2	varchar(20) not null
);


create sequence seq_abonos;

create table abonos(
	id_abono	integer primary key,
	cliente  	varchar(9) references clientes,
	saldo	    integer not null check (saldo>=0)
    );

create sequence seq_eventos;

create table eventos(
	id_evento	integer  primary key,
	nombre_evento		varchar(20),
    fecha       date not null,
	asientos_disponibles	integer  not null
);

create sequence seq_reservas;

-- Tabla de reservas
create table reservas(
	id_reserva	integer primary key,
	cliente  	varchar(9) references clientes,
    evento      integer references eventos,
	abono       integer references abonos,
	fecha	date not null
);
	
-- Procedimiento a implementar para realizar la reserva
create or replace procedure reservar_evento( arg_NIF_cliente varchar, arg_nombre_evento varchar, arg_fecha date) is

evento_sin_suceder exception;
pragma exception_init(evento_sin_suceder, -20001);
cliente_inexistente exception;
pragma exception_init(cliente_inexistente, -20002);
evento_inexistente exception;
pragma exception_init(evento_inexistente, -20003);
saldo_insuficiente exception;
pragma exception_init(saldo_insuficiente, -20004);
 
begin
    INSERT INTO reservas VALUES (seq_reservas.nextval, arg_NIF_cliente, seq_evento.nextval, seq_abonos.nextval, arg_fecha);
    UPDATE eventos SET asientos_disponibles=asientos_disponibles-1 WHERE arg_nombre_evento=evento;
    UPDATE abonos SET saldo=saldo-1 WHERE cliente=arg_NIF_cliente;
   
    SELECT asientos_disponibles INTO libres FROM eventos WHERE arg_nombre_evento = evento;
    if trunc(arg_fecha) < trunc(CURRENT_DATE) then
        rollback;
        raise_application_error(-20001,'No se pueden reservar eventos pasados.');
    else 
        SELECT count(*) into eventos_existentes from eventos where arg_nombre_evento = evento; --existe
        SELECT count(*) into clientes_existentes from clientes where arg_NIF_cliente = NIF; --existe cliente
        SELECT asientos_disponibles INTO libres from eventos WHERE arg_nombre_evento = evento; --libres
        SELECT saldo INTO dinero from abonos WHERE arg_NIF_cliente = cliente; --saldo
        if eventos_existentes < 1 then
            rollback;
        elsif clientes_existentes < 1 then
            rollback;
            raise_application_error(-20002,'Cliente inexistente.');
        elsif eventos_existentes < 1 then
            rollback;
            raise_application_error(-20003,'El evento ' ||arg_nombre_evento|| 'no existe.');
        elsif saldo < 1 then
            rollback;
            raise_application_error(-20004,'Saldo en abono insuficiente.');
        else
            commit;
        end if;
    end if;
end;
/


-- Tabla para comprobar que el evento no ha pasado. (Caso contrario devolverá el error -20001 con el mensaje 'No se pueden reservar eventos pasados.')
CREATE OR REPLACE PROCEDURE reservar_evento(arg_NIF_cliente VARCHAR, arg_nombre_evento VARCHAR, arg_fecha DATE) IS
  v_fecha_evento DATE;
BEGIN
  -- Para obtener la fecha del evento basado en arg_nombre_evento
  SELECT fecha INTO v_fecha_evento FROM eventos WHERE nombre_evento = arg_nombre_evento;
  
  -- Para comprobar si la fecha del evento ya pasó comparándola con la fecha actual del sistema
  IF v_fecha_evento < SYSDATE THEN
    -- Para lanzar un error si el evento ya pasó
    RAISE_APPLICATION_ERROR(-20001, 'No se pueden reservar eventos pasados.');
  ELSE
    -- Para proceder con la lógica de reserva si el evento no ha pasado
    INSERT INTO reservas VALUES (seq_reservas.nextval, arg_NIF_cliente, (SELECT id_evento FROM eventos WHERE nombre_evento = arg_nombre_evento), seq_abonos.nextval, arg_fecha);
    -- Para actualizar los asientos disponibles en la tabla de eventos
    UPDATE eventos SET asientos_disponibles = asientos_disponibles - 1 WHERE nombre_evento = arg_nombre_evento;
  END IF;

  COMMIT;
END;
/


------ Deja aquí tus respuestas a las preguntas del enunciado:
-- * P4.1
--
-- * P4.2
--
-- * P4.3
--
-- * P4.4
--
-- * P4.5
-- 


create or replace
procedure reset_seq( p_seq_name varchar )
is
    l_val number;
begin
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by -' || l_val || 
                                                          ' minvalue 0';
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

end;
/


create or replace procedure inicializa_test is
begin
  reset_seq( 'seq_abonos' );
  reset_seq( 'seq_eventos' );
  reset_seq( 'seq_reservas' );
        
  
    delete from reservas;
    delete from eventos;
    delete from abonos;
    delete from clientes;
    	
    insert into clientes values ('12345678A', 'Pepe', 'Perez', 'Porras');
    insert into clientes values ('11111111B', 'Beatriz', 'Barbosa', 'Bernardez');
    
    insert into abonos values (seq_abonos.nextval, '12345678A',10);
    insert into abonos values (seq_abonos.nextval, '11111111B',0);
    
    insert into eventos values ( seq_eventos.nextval, 'concierto_la_moda', date '2024-6-27', 200);
    insert into eventos values ( seq_eventos.nextval, 'teatro_impro', date '2024-7-1', 50);

    commit;
end;
/

exec inicializa_test;

-- Completa el test

create or replace procedure test_reserva_evento is
begin
	 
  --caso 1 Reserva correcta, se realiza
  begin
    inicializa_test;
  end;
  
  
  --caso 2 Evento pasado
  begin
    inicializa_test;
  end;
  
  --caso 3 Evento inexistente
  begin
    inicializa_test;
  end;
  

  --caso 4 Cliente inexistente  
  begin
    inicializa_test;
  end;
  
  --caso 5 El cliente no tiene saldo suficiente
  begin
    inicializa_test;
  end;

  
end;
/

CREATE OR REPLACE PROCEDURE test_reserva_evento_pasado IS
  v_error_expected EXCEPTION;
  PRAGMA EXCEPTION_INIT(v_error_expected, -20001);
BEGIN
  -- Intenta reservar un evento con fecha pasada
  -- Asumiendo que "concierto_la_moda" es el nombre de un evento y la fecha es anterior a la fecha actual
  reservar_evento('12345678A', 'concierto_la_moda', TO_DATE('2023-01-01', 'YYYY-MM-DD'));
EXCEPTION
  WHEN v_error_expected THEN
    dbms_output.put_line('Prueba exitosa: No se pueden reservar eventos pasados.');
  WHEN OTHERS THEN
    dbms_output.put_line('Error inesperado: ' || SQLERRM);
END;
/

set serveroutput on;
exec test_reserva_evento;
