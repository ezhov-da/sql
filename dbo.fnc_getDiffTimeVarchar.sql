USE []
GO
-----------------------------------------------------------------------
--> автор			: Ежов Д.А.
--> дата создания	: 2016-07-22 12:24
--> описание		: Функция возвращает разницу дат в указанном пользователем формате.
-->					константы для замены:
-->					:d - день
-->					:h - часы
-->					:m - минуты
-->					:s - секунды
-->					Если разница в днях = 0, замена происхлдит на пустоту
-->					@startDate - дата начала
-->					@endDate - дата окончания
-->					@template - шаблон для возврата результата, пример: :dд :h::m::s вернет 2д 14:45:12
------------------------------------------------------------------------

ALTER FUNCTION dbo.fnc_getDiffTimeVarchar (@startDate datetime, @endDate datetime, @template varchar(max))
RETURNS varchar(max)
WITH EXECUTE AS CALLER
AS
BEGIN
	/*
		В СВЯЗИ С ТЕМ, ЧТО ДЛЯ ФОРМУЛЫ НЕВОЗМОЖНО ВЫЧИСЛИТЬ СЕКУНДЫ ЧЕРЕЗ
		КОНСТРУКЦИЮ DATEDIFF(ss, @startDate, @endDate), ЕСЛИ
		ДАТА С, К ПРИМЕРУ: 2016-06-14 09:00:05.000,
		А ДАТА ПО: 2120-03-25 18:00:02.000 - МЫ ПОЛУЧАЕМ ОШИБКУ:
			Функция datediff вызвала переполнение. 
			Слишком большое количество частей даты, разделяющих два экземпляра даты-времени. 
			Попробуйте использовать функцию datediff с частью даты меньшей точности.
		РЕШИЛ ПОЙТИ ДРГИМ ПУТЕМ, А ИМЕННО - ВЫЧИСЛЯТЬ СЕКУНДЫ ИЗ ТЕКСТОВЫХ ПРЕДСТАВЛЕНИЙ.
		ТАК ЖЕ В СВЯЗИ С ТЕМ, ЧТО НАЙДЕННЫЕ РЕШЕНИЯ, ВОЗВРАЩАЮТ РАЗНИЦУ ДАТ:
		2016-06-21 15:25:20.000
		2016-06-21 16:18:06.000 		
		КАК: -7 минут

		РЕАЛИЗОВАЛИ ПОЛНОЕ ВЫЧИСЛЕНИЕ ЧЕРЕЗ СТРОКИ
	*/
	DECLARE @startDate120 varchar(50) =  CONVERT(VARCHAR, @startDate, 120)
	DECLARE @endDate120 varchar(50) =   CONVERT(VARCHAR, @endDate, 120)

	-- ПОЛУЧАЕМ СЕКУНДЫ	=============================================================================================================================
	declare @secondStartInt int = CONVERT(int, RIGHT(@startDate120,2))
	declare @secondEndInt int = CONVERT(int, RIGHT(@endDate120,2))
	declare @resultSecondDiff int 
	if (@secondEndInt < @secondStartInt)
	begin
		set @secondStartInt = case when @secondStartInt = 0 then @secondStartInt else  60 - @secondStartInt end
		set @resultSecondDiff = case when @secondStartInt + @secondEndInt = 60 then 0 else @secondStartInt + @secondEndInt end
	end
	else
	begin
		set @resultSecondDiff = @secondEndInt - @secondStartInt
	end
	--print @resultSecondDiff

	-- ПОЛУЧАЕМ МИНУТЫ =============================================================================================================================
	declare @minuteStartInt int = CONVERT(int, substring(@startDate120,15, 2))
	declare @minuteEndInt int = CONVERT(int, substring(@endDate120,15, 2))
	declare @resultMinuteDiff int
	if (@minuteEndInt < @minuteStartInt)
	begin
		set @minuteStartInt = case when @minuteStartInt = 0 then @minuteStartInt else  60 - @minuteStartInt end
		set @resultMinuteDiff = case when @minuteStartInt + @minuteEndInt = 60 then 0 else @minuteStartInt + @minuteEndInt end
	end
	else 
	begin
		set @resultMinuteDiff = @minuteEndInt - @minuteStartInt
	end
	set @resultMinuteDiff = case when @secondEndInt < @secondStartInt and @resultMinuteDiff != 0 then @resultMinuteDiff - 1 else @resultMinuteDiff end
	--print @resultMinuteDiff

	-- ПОЛУЧАЕМ ЧАСЫ =============================================================================================================================
	declare @hour int = DATEDIFF(hh, @startDate, @endDate) - (DATEDIFF(hh, @startDate, @endDate)/24)*24
	set @hour = case when @minuteEndInt < @minuteStartInt and @hour != 0 then @hour - 1 else @hour end
	--print @hour

	-- ПОЛУЧАЕМ ДНИ =============================================================================================================================
	declare @day int = DATEDIFF(hh, @startDate, @endDate)/24 
	--print @day
	
	set @template = case when @day = 0 then replace(@template, ':d', '') else replace(@template, ':d', @day) end
	set @template = replace(@template, ':h', RIGHT('00'+ISNULL(cast(@hour as varchar(3)),''),2))
	set @template = replace(@template, ':m', RIGHT('00'+ISNULL(cast(@resultMinuteDiff as varchar(3)),''),2))
	set @template = replace(@template, ':s', RIGHT('00'+ISNULL(cast(@resultSecondDiff as varchar(3)),''),2))

	return @template
END
GO

--ДАННЫЕ ДЛЯ ТЕСТИРОВАНИЯ

/*
select '2015-01-01 09:00:00.000' as startDate, '2016-12-31 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2015-01-01 09:00:00.000', 120), CONVERT(DATETIME, '2016-12-31 18:00:00.000', 120), ':d :h::m::s') as r union
select '2015-12-07 09:00:00.000' as startDate, '2016-07-08 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2015-12-07 09:00:00.000', 120), CONVERT(DATETIME, '2016-07-08 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-01 09:00:00.000' as startDate, '2016-06-17 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-01 09:00:00.000', 120), CONVERT(DATETIME, '2016-06-17 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-01 09:00:00.000' as startDate, '2016-12-31 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-01 09:00:00.000', 120), CONVERT(DATETIME, '2016-12-31 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-11 00:00:00.000' as startDate, '2016-01-11 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-11 00:00:00.000', 120), CONVERT(DATETIME, '2016-01-11 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-11 00:00:00.000' as startDate, '2016-01-17 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-11 00:00:00.000', 120), CONVERT(DATETIME, '2016-01-17 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-14 00:00:00.000' as startDate, '2016-04-13 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-14 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-13 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-18 00:00:00.000' as startDate, '2016-01-24 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-18 00:00:00.000', 120), CONVERT(DATETIME, '2016-01-24 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-18 00:00:00.000' as startDate, '2016-02-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-18 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-25 00:00:00.000' as startDate, '2016-01-31 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-25 00:00:00.000', 120), CONVERT(DATETIME, '2016-01-31 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-25 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-25 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-27 00:00:00.000' as startDate, '2016-01-27 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-27 00:00:00.000', 120), CONVERT(DATETIME, '2016-01-27 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-27 00:00:00.000' as startDate, '2016-02-16 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-27 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-16 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-01-29 00:00:00.000' as startDate, '2016-05-13 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-01-29 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-13 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-01 00:00:00.000' as startDate, '2016-02-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-01 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-01 00:00:00.000' as startDate, '2016-02-07 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-01 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-07 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-01 00:00:00.000' as startDate, '2016-02-15 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-01 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-01 00:00:00.000' as startDate, '2016-03-31 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-01 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-31 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-02 00:00:00.000' as startDate, '2016-03-02 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-02 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-02 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-03 00:00:00.000' as startDate, '2016-03-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-03 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-04 00:00:00.000' as startDate, '2016-02-04 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-04 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-04 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-05 00:00:00.000' as startDate, '2016-02-05 15:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-05 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-05 15:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-05 00:00:00.000' as startDate, '2016-02-08 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-05 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-08 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-05 00:00:00.000' as startDate, '2016-02-09 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-05 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-09 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-05 00:00:00.000' as startDate, '2016-02-12 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-05 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-12 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-05 00:00:00.000' as startDate, '2016-02-15 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-05 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-05 00:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-05 00:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-05 08:30:00.000' as startDate, '2016-02-05 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-05 08:30:00.000', 120), CONVERT(DATETIME, '2016-02-05 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-05 09:00:00.000' as startDate, '2016-03-30 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-05 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-30 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-07 09:00:00.000' as startDate, '2016-06-17 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-07 09:00:00.000', 120), CONVERT(DATETIME, '2016-06-17 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-08 00:00:00.000' as startDate, '2016-02-11 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-08 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-11 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-08 00:00:00.000' as startDate, '2016-02-12 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-08 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-12 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-08 00:00:00.000' as startDate, '2016-02-15 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-08 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-08 00:00:00.000' as startDate, '2016-02-29 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-08 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-29 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-08 00:00:00.000' as startDate, '2016-04-30 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-08 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-30 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-09 00:00:00.000' as startDate, '2016-02-10 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-09 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-10 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-09 00:00:00.000' as startDate, '2016-02-11 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-09 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-11 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-09 00:00:00.000' as startDate, '2016-02-12 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-09 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-12 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-09 00:00:00.000' as startDate, '2016-02-19 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-09 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-09 00:00:00.000' as startDate, '2016-02-29 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-09 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-29 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-09 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-09 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-09 17:00:00.000' as startDate, '2016-03-01 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-09 17:00:00.000', 120), CONVERT(DATETIME, '2016-03-01 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-10 00:00:00.000' as startDate, '2016-02-10 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-10 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-10 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-10 00:00:00.000' as startDate, '2016-02-29 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-10 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-29 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-11 00:00:00.000' as startDate, '2016-02-11 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-11 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-11 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-11 00:00:00.000' as startDate, '2016-02-12 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-11 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-12 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-11 00:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-11 00:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 00:00:00.000' as startDate, '2016-02-12 13:55:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-12 13:55:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 00:00:00.000' as startDate, '2016-02-13 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-13 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 00:00:00.000' as startDate, '2016-02-19 09:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 09:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 00:00:00.000' as startDate, '2016-03-02 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-02 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 00:00:00.000' as startDate, '2016-03-04 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-04 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 08:30:00.000' as startDate, '2016-02-12 15:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 08:30:00.000', 120), CONVERT(DATETIME, '2016-02-12 15:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 10:00:00.000' as startDate, '2016-02-12 12:35:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 10:00:00.000', 120), CONVERT(DATETIME, '2016-02-12 12:35:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 10:00:00.000' as startDate, '2016-02-12 16:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 10:00:00.000', 120), CONVERT(DATETIME, '2016-02-12 16:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 10:20:00.000' as startDate, '2016-02-12 11:20:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 10:20:00.000', 120), CONVERT(DATETIME, '2016-02-12 11:20:00.000', 120), ':d :h::m::s') as r union
select '2016-02-12 11:14:00.000' as startDate, '2016-02-12 16:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-12 11:14:00.000', 120), CONVERT(DATETIME, '2016-02-12 16:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 00:00:00.000' as startDate, '2016-02-15 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 00:00:00.000' as startDate, '2016-02-16 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-16 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 00:00:00.000' as startDate, '2016-02-18 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-18 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 00:00:00.000' as startDate, '2016-02-19 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 00:00:00.000' as startDate, '2016-02-29 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-29 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 00:00:00.000' as startDate, '2016-03-11 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-11 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 00:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 00:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 08:30:00.000' as startDate, '2016-02-16 11:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 08:30:00.000', 120), CONVERT(DATETIME, '2016-02-16 11:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 11:00:00.000' as startDate, '2016-02-15 15:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 11:00:00.000', 120), CONVERT(DATETIME, '2016-02-15 15:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 15:40:00.000' as startDate, '2016-02-16 09:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 15:40:00.000', 120), CONVERT(DATETIME, '2016-02-16 09:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 15:45:00.000' as startDate, '2016-02-15 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 15:45:00.000', 120), CONVERT(DATETIME, '2016-02-15 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 16:00:00.000' as startDate, '2016-02-15 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 16:00:00.000', 120), CONVERT(DATETIME, '2016-02-15 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-15 17:00:00.000' as startDate, '2016-02-15 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-15 17:00:00.000', 120), CONVERT(DATETIME, '2016-02-15 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 00:00:00.000' as startDate, '2016-02-16 23:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-16 23:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 00:00:00.000' as startDate, '2016-02-17 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-17 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 00:00:00.000' as startDate, '2016-02-18 23:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-18 23:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 00:00:00.000' as startDate, '2016-02-19 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 00:00:00.000' as startDate, '2016-02-20 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 00:00:00.000' as startDate, '2016-12-31 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 00:00:00.000', 120), CONVERT(DATETIME, '2016-12-31 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 09:00:00.000' as startDate, '2016-02-16 14:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-16 14:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 09:01:30.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 09:01:30.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 10:00:00.000' as startDate, '2016-02-17 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 10:00:00.000', 120), CONVERT(DATETIME, '2016-02-17 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 10:53:00.000' as startDate, '2016-02-16 10:57:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 10:53:00.000', 120), CONVERT(DATETIME, '2016-02-16 10:57:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 10:59:00.000' as startDate, '2016-02-16 10:59:16.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 10:59:00.000', 120), CONVERT(DATETIME, '2016-02-16 10:59:16.000', 120), ':d :h::m::s') as r union
select '2016-02-16 11:07:00.000' as startDate, '2016-02-16 11:28:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 11:07:00.000', 120), CONVERT(DATETIME, '2016-02-16 11:28:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 11:30:00.000' as startDate, '2016-02-16 12:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 11:30:00.000', 120), CONVERT(DATETIME, '2016-02-16 12:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 14:00:00.000' as startDate, '2016-02-16 14:55:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 14:00:00.000', 120), CONVERT(DATETIME, '2016-02-16 14:55:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 14:05:32.000' as startDate, '2016-02-19 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 14:05:32.000', 120), CONVERT(DATETIME, '2016-02-19 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-16 16:00:00.000' as startDate, '2016-02-16 16:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-16 16:00:00.000', 120), CONVERT(DATETIME, '2016-02-16 16:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 00:00:00.000' as startDate, '2016-02-17 23:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-17 23:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 00:00:00.000' as startDate, '2016-02-20 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 00:00:00.000' as startDate, '2016-02-24 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-24 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 00:00:00.000' as startDate, '2016-02-29 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-29 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 00:00:00.000' as startDate, '2016-06-17 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 00:00:00.000', 120), CONVERT(DATETIME, '2016-06-17 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 08:30:00.000' as startDate, '2016-02-17 09:58:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 08:30:00.000', 120), CONVERT(DATETIME, '2016-02-17 09:58:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 10:00:00.000' as startDate, '2016-02-17 11:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 10:00:00.000', 120), CONVERT(DATETIME, '2016-02-17 11:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 11:30:00.000' as startDate, '2016-02-17 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 11:30:00.000', 120), CONVERT(DATETIME, '2016-02-17 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 12:29:00.000' as startDate, '2016-02-17 14:52:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 12:29:00.000', 120), CONVERT(DATETIME, '2016-02-17 14:52:00.000', 120), ':d :h::m::s') as r union
select '2016-02-17 15:00:00.000' as startDate, '2016-02-17 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-17 15:00:00.000', 120), CONVERT(DATETIME, '2016-02-17 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-18 00:00:00.000' as startDate, '2016-02-20 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-18 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-18 00:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-18 00:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-18 08:30:00.000' as startDate, '2016-02-19 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-18 08:30:00.000', 120), CONVERT(DATETIME, '2016-02-19 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-18 09:00:00.000' as startDate, '2016-02-26 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-18 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-26 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-18 09:00:00.000' as startDate, '2016-03-02 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-18 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-02 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:00:00.000' as startDate, '2016-02-19 09:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 09:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:00:00.000' as startDate, '2016-02-19 09:38:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 09:38:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:00:00.000' as startDate, '2016-02-19 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:00:00.000' as startDate, '2016-02-19 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:00:00.000' as startDate, '2016-02-24 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-24 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:00:00.000' as startDate, '2016-03-03 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-03 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:00:00.000' as startDate, '2016-03-11 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-11 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:34:00.000' as startDate, '2016-02-19 09:38:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:34:00.000', 120), CONVERT(DATETIME, '2016-02-19 09:38:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:38:00.000' as startDate, '2016-02-19 09:50:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:38:00.000', 120), CONVERT(DATETIME, '2016-02-19 09:50:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:40:00.000' as startDate, '2016-02-19 10:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:40:00.000', 120), CONVERT(DATETIME, '2016-02-19 10:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 09:41:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 09:41:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 10:00:00.000' as startDate, '2016-02-19 12:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 10:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 12:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 10:09:00.000' as startDate, '2016-02-19 10:46:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 10:09:00.000', 120), CONVERT(DATETIME, '2016-02-19 10:46:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 10:11:00.000' as startDate, '2016-02-20 11:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 10:11:00.000', 120), CONVERT(DATETIME, '2016-02-20 11:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 10:12:00.000' as startDate, '2016-02-19 11:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 10:12:00.000', 120), CONVERT(DATETIME, '2016-02-19 11:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 10:54:00.000' as startDate, '2016-02-19 10:46:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 10:54:00.000', 120), CONVERT(DATETIME, '2016-02-19 10:46:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 11:40:00.000' as startDate, '2016-02-19 12:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 11:40:00.000', 120), CONVERT(DATETIME, '2016-02-19 12:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 12:10:01.000' as startDate, '2016-02-19 12:29:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 12:10:01.000', 120), CONVERT(DATETIME, '2016-02-19 12:29:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 12:36:00.000' as startDate, '2016-02-20 13:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 12:36:00.000', 120), CONVERT(DATETIME, '2016-02-20 13:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 12:50:00.000' as startDate, '2016-02-19 13:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 12:50:00.000', 120), CONVERT(DATETIME, '2016-02-19 13:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 14:00:00.000' as startDate, '2016-02-19 15:50:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 14:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 15:50:00.000', 120), ':d :h::m::s') as r union
select '2016-02-19 16:00:00.000' as startDate, '2016-02-19 16:40:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-19 16:00:00.000', 120), CONVERT(DATETIME, '2016-02-19 16:40:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 08:30:00.000' as startDate, '2016-02-20 09:15:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 08:30:00.000', 120), CONVERT(DATETIME, '2016-02-20 09:15:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 09:00:00.000' as startDate, '2016-02-20 20:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 20:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 09:00:00.000' as startDate, '2016-02-20 22:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 22:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 09:00:00.000' as startDate, '2016-02-24 13:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-24 13:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 09:00:00.000' as startDate, '2016-02-24 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-24 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 09:16:00.000' as startDate, '2016-02-20 10:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 09:16:00.000', 120), CONVERT(DATETIME, '2016-02-20 10:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 10:01:00.000' as startDate, '2016-02-20 10:10:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 10:01:00.000', 120), CONVERT(DATETIME, '2016-02-20 10:10:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 11:00:00.000' as startDate, '2016-02-20 11:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 11:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 11:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 11:30:00.000' as startDate, '2016-02-20 11:40:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 11:30:00.000', 120), CONVERT(DATETIME, '2016-02-20 11:40:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 11:30:00.000' as startDate, '2016-02-20 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 11:30:00.000', 120), CONVERT(DATETIME, '2016-02-20 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 11:40:00.000' as startDate, '2016-02-20 12:08:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 11:40:00.000', 120), CONVERT(DATETIME, '2016-02-20 12:08:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 12:00:00.000' as startDate, '2016-02-20 13:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 12:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 13:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 13:00:00.000' as startDate, '2016-02-20 14:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 13:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 14:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 14:00:00.000' as startDate, '2016-02-20 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 14:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 15:00:00.000' as startDate, '2016-02-20 15:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 15:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 15:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 15:00:00.000' as startDate, '2016-02-25 19:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 15:00:00.000', 120), CONVERT(DATETIME, '2016-02-25 19:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 15:00:00.000' as startDate, '2016-02-25 20:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 15:00:00.000', 120), CONVERT(DATETIME, '2016-02-25 20:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 16:00:00.000' as startDate, '2016-02-20 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 16:00:00.000', 120), CONVERT(DATETIME, '2016-02-20 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-20 16:25:00.000' as startDate, '2016-02-20 16:35:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-20 16:25:00.000', 120), CONVERT(DATETIME, '2016-02-20 16:35:00.000', 120), ':d :h::m::s') as r union
select '2016-02-24 00:00:00.000' as startDate, '2016-02-24 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-24 00:00:00.000', 120), CONVERT(DATETIME, '2016-02-24 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-24 00:00:00.000' as startDate, '2016-03-18 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-24 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-18 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-24 08:30:00.000' as startDate, '2016-02-24 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-24 08:30:00.000', 120), CONVERT(DATETIME, '2016-02-24 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-24 09:00:00.000' as startDate, '2016-02-24 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-24 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-24 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-24 09:00:00.000' as startDate, '2016-02-26 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-24 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-26 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-24 09:00:00.000' as startDate, '2016-03-10 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-24 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-10 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-24 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-24 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 08:30:00.000' as startDate, '2016-02-25 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 08:30:00.000', 120), CONVERT(DATETIME, '2016-02-25 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 08:30:00.000' as startDate, '2016-03-15 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 08:30:00.000', 120), CONVERT(DATETIME, '2016-03-15 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 08:30:00.000' as startDate, '2016-03-31 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 08:30:00.000', 120), CONVERT(DATETIME, '2016-03-31 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 09:00:00.000' as startDate, '2016-02-25 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-25 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 09:00:00.000' as startDate, '2016-02-29 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-29 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 09:00:00.000' as startDate, '2016-03-03 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-03 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 09:00:00.000' as startDate, '2016-03-12 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-12 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 09:00:00.000' as startDate, '2016-04-11 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-11 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 10:00:00.000' as startDate, '2016-02-25 11:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 10:00:00.000', 120), CONVERT(DATETIME, '2016-02-25 11:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-25 11:00:00.000' as startDate, '2016-02-25 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-25 11:00:00.000', 120), CONVERT(DATETIME, '2016-02-25 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-02-26 09:00:00.000' as startDate, '2016-02-26 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-26 09:00:00.000', 120), CONVERT(DATETIME, '2016-02-26 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-26 09:00:00.000' as startDate, '2016-03-31 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-26 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-31 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-26 09:00:00.000' as startDate, '2016-04-30 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-26 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-30 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-29 00:00:00.000' as startDate, '2016-03-06 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-29 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-06 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-29 09:00:00.000' as startDate, '2016-03-01 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-29 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-01 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-29 09:00:00.000' as startDate, '2016-03-04 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-29 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-04 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-29 09:00:00.000' as startDate, '2016-03-09 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-29 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-09 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-29 09:00:00.000' as startDate, '2016-03-10 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-29 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-10 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-29 09:00:00.000' as startDate, '2016-05-02 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-29 09:00:00.000', 120), CONVERT(DATETIME, '2016-05-02 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-02-29 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-02-29 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-01 09:00:00.000' as startDate, '2016-03-04 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-01 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-04 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-01 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-01 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-01 11:00:00.000' as startDate, '2016-03-04 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-01 11:00:00.000', 120), CONVERT(DATETIME, '2016-03-04 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-02 00:00:00.000' as startDate, '2016-05-20 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-02 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-20 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-02 09:00:00.000' as startDate, '2016-03-02 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-02 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-02 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-03-02 09:00:00.000' as startDate, '2016-03-11 13:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-02 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-11 13:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-02 09:00:00.000' as startDate, '2016-03-11 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-02 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-11 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-02 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-02 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-02 14:00:00.000' as startDate, '2016-03-02 16:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-02 14:00:00.000', 120), CONVERT(DATETIME, '2016-03-02 16:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-04 09:00:00.000' as startDate, '2016-03-11 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-04 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-11 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-04 09:00:00.000' as startDate, '2016-03-18 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-04 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-18 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-07 00:00:00.000' as startDate, '2016-03-13 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-07 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-13 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-07 08:30:00.000' as startDate, '2016-04-30 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-07 08:30:00.000', 120), CONVERT(DATETIME, '2016-04-30 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-03-07 09:00:00.000' as startDate, '2016-03-11 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-07 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-11 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-10 00:00:00.000' as startDate, '2016-03-17 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-10 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-17 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-10 00:00:00.000' as startDate, '2016-04-11 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-10 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-11 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-10 00:00:00.000' as startDate, '2016-05-10 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-10 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-10 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-10 09:00:00.000' as startDate, '2016-03-15 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-10 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-15 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-10 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-10 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-14 00:00:00.000' as startDate, '2016-03-20 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-14 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-20 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-14 09:00:00.000' as startDate, '2016-05-01 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-14 09:00:00.000', 120), CONVERT(DATETIME, '2016-05-01 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-15 00:00:00.000' as startDate, '2016-03-15 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-15 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-15 00:00:00.000' as startDate, '2016-05-06 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-06 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-15 00:00:00.000' as startDate, '2016-05-15 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-15 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-15 09:00:00.000' as startDate, '2016-03-15 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-15 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-15 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-15 09:00:00.000' as startDate, '2016-03-15 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-15 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-15 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-15 17:26:31.000' as startDate, '2016-03-15 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-15 17:26:31.000', 120), CONVERT(DATETIME, '2016-03-15 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-16 00:00:00.000' as startDate, '2016-03-16 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-16 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-16 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-16 00:00:00.000' as startDate, '2016-04-14 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-16 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-14 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-16 08:45:00.000' as startDate, '2016-03-16 10:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-16 08:45:00.000', 120), CONVERT(DATETIME, '2016-03-16 10:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-16 09:00:00.000' as startDate, '2016-03-23 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-16 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-23 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-18 00:00:00.000' as startDate, '2016-05-13 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-18 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-13 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-21 00:00:00.000' as startDate, '2016-03-27 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-21 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-27 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-21 09:00:00.000' as startDate, '2016-05-29 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-21 09:00:00.000', 120), CONVERT(DATETIME, '2016-05-29 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-21 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-21 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-22 00:00:00.000' as startDate, '2016-05-13 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-22 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-13 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-22 09:00:00.000' as startDate, '2016-03-25 16:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-22 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-25 16:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-22 09:00:00.000' as startDate, '2016-03-30 10:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-22 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-30 10:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-22 09:00:00.000' as startDate, '2016-05-20 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-22 09:00:00.000', 120), CONVERT(DATETIME, '2016-05-20 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-23 00:00:00.000' as startDate, '2016-03-27 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-23 00:00:00.000', 120), CONVERT(DATETIME, '2016-03-27 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-23 09:00:00.000' as startDate, '2016-04-24 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-23 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-24 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-24 09:00:00.000' as startDate, '2016-03-29 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-24 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-29 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-28 00:00:00.000' as startDate, '2016-04-03 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-28 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-03 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-03-31 09:00:00.000' as startDate, '2016-03-31 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-03-31 09:00:00.000', 120), CONVERT(DATETIME, '2016-03-31 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-01 00:00:00.000' as startDate, '2016-04-30 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-01 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-30 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-01 00:00:00.000' as startDate, '2016-05-31 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-01 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-31 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-01 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-01 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-04 00:00:00.000' as startDate, '2016-04-10 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-04 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-10 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-04 00:00:00.000' as startDate, '2016-04-15 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-04 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-15 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-04 09:00:00.000' as startDate, '2016-04-05 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-04 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-05 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-04 09:00:00.000' as startDate, '2016-04-06 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-04 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-06 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-04 09:00:00.000' as startDate, '2016-04-10 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-04 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-10 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-04 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-04 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-05 09:00:00.000' as startDate, '2016-04-05 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-05 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-05 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-05 09:00:00.000' as startDate, '2016-04-12 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-05 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-12 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-05 12:00:00.000' as startDate, '2016-04-08 11:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-05 12:00:00.000', 120), CONVERT(DATETIME, '2016-04-08 11:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-06 00:00:00.000' as startDate, '2016-04-28 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-06 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-28 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-06 09:00:00.000' as startDate, '2016-04-05 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-06 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-05 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-06 09:00:00.000' as startDate, '2016-04-11 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-06 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-11 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-06 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-06 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-07 00:00:00.000' as startDate, '2016-05-27 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-07 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-27 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-07 00:00:00.000' as startDate, '2016-05-31 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-07 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-31 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-07 09:00:00.000' as startDate, '2016-04-14 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-07 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-14 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-07 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-07 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-08 00:00:00.000' as startDate, '2016-05-11 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-08 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-11 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-08 00:00:00.000' as startDate, '2016-05-30 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-08 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-30 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-08 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-08 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 00:00:00.000' as startDate, '2016-04-17 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-17 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 00:00:00.000' as startDate, '2016-05-11 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-11 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 00:00:00.000' as startDate, '2016-05-20 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-20 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 09:00:00.000' as startDate, '2016-04-11 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-11 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 09:00:00.000' as startDate, '2016-04-11 17:20:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-11 17:20:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 09:00:00.000' as startDate, '2016-04-13 14:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-13 14:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 09:00:00.000' as startDate, '2016-04-14 10:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-14 10:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 09:00:00.000' as startDate, '2016-04-15 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-15 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 09:00:00.000' as startDate, '2016-04-17 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-17 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-11 09:00:00.000' as startDate, '2016-04-22 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-11 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-22 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-12 08:54:00.000' as startDate, '2016-04-13 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-12 08:54:00.000', 120), CONVERT(DATETIME, '2016-04-13 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-12 09:00:00.000' as startDate, '2016-04-13 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-12 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-13 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-12 09:00:00.000' as startDate, '2016-04-15 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-12 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-15 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-12 09:00:00.000' as startDate, '2016-04-25 11:45:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-12 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-25 11:45:00.000', 120), ':d :h::m::s') as r union
select '2016-04-12 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-12 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-13 00:00:00.000' as startDate, '2016-04-13 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-13 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-13 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-13 09:00:00.000' as startDate, '2016-04-13 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-13 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-13 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-13 09:00:00.000' as startDate, '2016-04-15 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-13 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-15 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-13 09:00:00.000' as startDate, '2016-04-19 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-13 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-19 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-14 00:00:00.000' as startDate, '2016-05-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-14 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-14 00:00:00.000' as startDate, '2016-05-11 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-14 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-11 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-14 00:00:00.000' as startDate, '2016-05-20 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-14 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-20 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-14 09:00:00.000' as startDate, '2016-04-15 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-14 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-15 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-14 09:00:00.000' as startDate, '2016-04-29 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-14 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-29 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-14 09:00:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-14 09:00:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-15 00:00:00.000' as startDate, '2016-04-15 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-15 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-15 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-15 08:30:00.000' as startDate, '2016-07-01 17:30:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-15 08:30:00.000', 120), CONVERT(DATETIME, '2016-07-01 17:30:00.000', 120), ':d :h::m::s') as r union
select '2016-04-15 09:00:00.000' as startDate, '2016-04-18 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-15 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-18 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-15 09:00:00.000' as startDate, '2016-04-19 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-15 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-19 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-15 09:00:00.000' as startDate, '2016-04-22 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-15 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-22 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 00:00:00.000' as startDate, '2016-04-24 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-24 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 09:00:00.000' as startDate, '2016-04-18 12:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-18 12:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 09:00:00.000' as startDate, '2016-04-18 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-18 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 09:00:00.000' as startDate, '2016-04-19 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-19 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 09:00:00.000' as startDate, '2016-04-20 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-20 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 09:00:00.000' as startDate, '2016-04-21 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-21 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 09:00:00.000' as startDate, '2016-04-22 13:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-22 13:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 09:00:00.000' as startDate, '2016-04-25 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-25 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 13:00:00.000' as startDate, '2016-04-18 14:20:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 13:00:00.000', 120), CONVERT(DATETIME, '2016-04-18 14:20:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 15:00:00.000' as startDate, '2016-04-18 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 15:00:00.000', 120), CONVERT(DATETIME, '2016-04-18 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-18 19:00:00.000' as startDate, '2016-04-19 12:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-18 19:00:00.000', 120), CONVERT(DATETIME, '2016-04-19 12:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-19 00:00:00.000' as startDate, '2016-04-19 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-19 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-19 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-19 09:00:00.000' as startDate, '2016-04-19 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-19 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-19 09:00:00.000' as startDate, '2016-04-20 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-20 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-19 09:00:00.000' as startDate, '2016-04-22 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-19 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-22 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-19 14:00:00.000' as startDate, '2016-04-19 20:20:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-19 14:00:00.000', 120), CONVERT(DATETIME, '2016-04-19 20:20:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 00:00:00.000' as startDate, '2016-04-20 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 00:00:00.000', 120), CONVERT(DATETIME, '2016-04-20 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 09:00:00.000' as startDate, '2016-04-20 10:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-20 10:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 09:00:00.000' as startDate, '2016-04-20 13:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-20 13:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 09:00:00.000' as startDate, '2016-04-20 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-20 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 09:00:00.000' as startDate, '2016-04-21 16:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-21 16:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 09:00:00.000' as startDate, '2016-04-21 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-21 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 09:00:00.000' as startDate, '2016-04-27 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-27 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 09:00:00.000' as startDate, '2016-04-29 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-29 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 09:00:00.000' as startDate, '2016-06-22 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 09:00:00.000', 120), CONVERT(DATETIME, '2016-06-22 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-20 14:30:00.000' as startDate, '4000-01-01 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-20 14:30:00.000', 120), CONVERT(DATETIME, '4000-01-01 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-21 00:00:00.000' as startDate, '2016-05-10 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-21 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-10 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-21 00:00:00.000' as startDate, '2016-05-11 00:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-21 00:00:00.000', 120), CONVERT(DATETIME, '2016-05-11 00:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-21 09:00:00.000' as startDate, '2016-04-21 17:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-21 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-21 17:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-21 09:00:00.000' as startDate, '2016-04-21 18:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-21 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-21 18:00:00.000', 120), ':d :h::m::s') as r union
select '2016-04-21 09:00:00.000' as startDate, '2016-04-22 16:00:00.000'as endDate,dbo.fnc_E_getTimeVarchar(CONVERT(DATETIME, '2016-04-21 09:00:00.000', 120), CONVERT(DATETIME, '2016-04-22 16:00:00.000', 120), ':d :h::m::s') as r 
*/