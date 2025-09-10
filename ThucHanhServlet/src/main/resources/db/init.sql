-- Create database if not exists
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DbTmp')
BEGIN
    CREATE DATABASE DbTmp;
END
GO

USE DbTmp;
GO

-- Create schema if not exists
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbo')
BEGIN
    EXEC('CREATE SCHEMA dbo');
END
GO

-- Grant permissions
GRANT ALTER, CONTROL, DELETE, EXECUTE, INSERT, REFERENCES, SELECT, UPDATE, VIEW DEFINITION ON SCHEMA::dbo TO sa;
GO

-- Create Category table if not exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Category]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Category](
        [cateid] [int] IDENTITY(1,1) NOT NULL,
        [catename] [nvarchar](255) NULL,
        [icon] [nvarchar](255) NULL,
        [userid] [int] NULL,
        CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED 
        (
            [cateid] ASC
        )
    );
END
GO
