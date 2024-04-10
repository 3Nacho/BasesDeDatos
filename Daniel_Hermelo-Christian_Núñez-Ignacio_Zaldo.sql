-- Repositorio: https://github.com/3Nacho/BasesDeDatos
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
	

CREATE OR REPLACE PROCEDURE reservar_evento(arg_NIF_cliente VARCHAR, arg_nombre_evento VARCHAR, arg_fecha DATE) IS
    evento_pasado EXCEPTION;
    PRAGMA EXCEPTION_INIT(evento_pasado, -20001);
    cliente_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(cliente_inexistente, -20002);
    evento_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(evento_inexistente, -20003);
    saldo_insuficiente EXCEPTION;
    PRAGMA EXCEPTION_INIT(saldo_insuficiente, -20004);
    
    v_id_evento INTEGER;
    v_saldo INTEGER;
    v_asientos_disponibles INTEGER;
    v_eventos_existentes INTEGER;
    v_clientes_existentes INTEGER;
    v_libres INTEGER;
    v_dinero INTEGER;

    BEGIN
    -- Primero, verificar si la fecha del evento es futura
    IF TRUNC(arg_fecha) < TRUNC(CURRENT_DATE) THEN
        RAISE_APPLICATION_ERROR(-20001, 'No se pueden reservar eventos pasados.');   
    END IF;

    DELETE from eventos where nombre_evento = arg_nombre_evento;
    if sql%rowcount = 0 then
        rollback;
        RAISE_APPLICATION_ERROR(-20003, 'El evento ' ||arg_nombre_evento|| 'no existe.');
    else
        commit;
    end if;

    DELETE from clientes where NIF = arg_NIF_cliente;
    if sql%rowcount = 0 then
        rollback;
        RAISE_APPLICATION_ERROR(-20002,'Cliente inexistente.');
    else
        commit;
    end if;
            
    -- Si el evento no tiene asientos disponibles, lanzar excepción
    IF v_asientos_disponibles < 1 THEN
        RAISE saldo_insuficiente;
    END IF;

    SELECT saldo INTO dinero from abonos WHERE arg_NIF_cliente = cliente;
    if dinero < 1 then
        rollback;
        raise_application_error(-20004,'Saldo en abono insuficiente.');
    
    -- Si todo es correcto, realizar la reserva
    INSERT INTO reservas (id_reserva, cliente, evento, fecha)
    VALUES (seq_reservas.NEXTVAL, arg_NIF_cliente, v_id_evento, arg_fecha);

    -- Actualizar el saldo del abono del cliente
    UPDATE abonos SET saldo = saldo - 1
    WHERE cliente = arg_NIF_cliente;

    -- Disminuir los asientos disponibles del evento
    UPDATE eventos SET asientos_disponibles = asientos_disponibles - 1
    WHERE id_evento = v_id_evento;
    
    commit;

EXCEPTION
<<<<<<< HEAD
=======
    WHEN evento_pasado THEN
        RAISE_APPLICATION_ERROR(-20001, 'No se pueden reservar eventos pasados.');
    WHEN cliente_inexistente THEN
        RAISE_APPLICATION_ERROR(-20002,'Cliente inexistente.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'El evento ' ||arg_nombre_evento|| ' no existe.');
>>>>>>> fb358faad40ff791544e56810ebbed7ec5984f55
    WHEN saldo_insuficiente THEN
        RAISE_APPLICATION_ERROR(-20004, 'Saldo en abono insuficiente.');
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

  -- Variables para contar la operación
    cont_antes_de_la_reserva INTEGER;
    cont_despues_de_la_reserva INTEGER;

begin
      
  --caso 1 Reserva correcta, se realiza
  begin
    inicializa_test;
    
    
    -- Conteo antes de la reserva
    SELECT COUNT(*) INTO cont_antes_de_la_reserva FROM reservas;
    
    -- Hacemos una reserva valida
    reservar_evento('12345678A', 'concierto_la_moda', TO_DATE('2024-06-27', 'YYYY-MM-DD'));
    
    -- Conteo después de la reserva
    SELECT COUNT(*) INTO cont_despues_de_la_reserva FROM reservas;
    
    -- Verificamos si la prueba es exitosa
    IF cont_despues_de_la_reserva = cont_antes_de_la_reserva + 1 THEN
      dbms_output.put_line('T1: Prueba exitosa: La reserva se realizó correctamente.');
    ELSE
      dbms_output.put_line('T1: Prueba fallida: La cantidad de reservas no aumentó como se esperaba.');
    END IF;
    
  EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('T1: Error inesperado: ' || SQLERRM);
    
  end;
  
  --caso 2 Evento pasado
  begin
    inicializa_test;
    reservar_evento('12345678A', 'concierto_la_moda', TO_DATE('2023-01-01', 'YYYY-MM-DD'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20001 THEN
        dbms_output.put_line('T2: Prueba exitosa: No se pueden reservar eventos pasados. SQL Error: ' || SQLCODE || ' ' || SQLERRM);
      ELSE
        dbms_output.put_line('T2: Error inesperado: ' || SQLERRM);
      END IF;
  end;
  
  --caso 3 Evento inexistente
  begin
    inicializa_test;
    reservar_evento('12345678A', 'evento_fantasma', TO_DATE('2024-06-28', 'YYYY-MM-DD'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20003 THEN
        dbms_output.put_line('T3: Prueba exitosa: El evento no existe. SQL Error: ' || SQLCODE || ' ' || SQLERRM);
      ELSE
        dbms_output.put_line('T3: Error inesperado: ' || SQLERRM);
      END IF;
  end;
  
  --caso 4 Cliente inexistente
  begin
    inicializa_test;
    reservar_evento('99999999X', 'concierto_la_moda', TO_DATE('2024-06-27', 'YYYY-MM-DD'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20002 THEN
        dbms_output.put_line('T4: Prueba exitosa: Cliente inexistente. SQL Error: ' || SQLCODE || ' ' || SQLERRM);
      ELSE
        dbms_output.put_line('T4: Error inesperado: ' || SQLERRM);
      END IF;
  end;
  
  --caso 5 El cliente no tiene saldo suficiente
  begin
    inicializa_test;
    reservar_evento('11111111B', 'concierto_la_moda', TO_DATE('2024-06-27', 'YYYY-MM-DD'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20004 THEN
        dbms_output.put_line('T5: Prueba exitosa: Saldo en abono insuficiente. SQL Error: ' || SQLCODE || ' ' || SQLERRM);
      ELSE
        dbms_output.put_line('T5: Error inesperado: ' || SQLERRM);
      END IF;
  end;

end;
/


set serveroutput on;
exec test_reserva_evento;
