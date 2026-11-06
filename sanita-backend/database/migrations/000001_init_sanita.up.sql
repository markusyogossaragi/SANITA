-- SANITA Database Migration 000001: Core Entities
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    full_name VARCHAR(128) NOT NULL,
    role VARCHAR(32) NOT NULL DEFAULT 'user_demo',
    password VARCHAR(255) NOT NULL,
    email_enc TEXT,
    phone_enc TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS checklists (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    lokasi VARCHAR(128) NOT NULL,
    air_bersih BOOLEAN NOT NULL DEFAULT FALSE,
    toilet_bersih BOOLEAN NOT NULL DEFAULT FALSE,
    tempat_sampah BOOLEAN NOT NULL DEFAULT FALSE,
    ventilasi_udara BOOLEAN NOT NULL DEFAULT FALSE,
    bebas_genangan BOOLEAN NOT NULL DEFAULT FALSE,
    kebersihan_area BOOLEAN NOT NULL DEFAULT FALSE,
    skor_terpenuhi INT NOT NULL DEFAULT 0,
    total_kondisi INT NOT NULL DEFAULT 6,
    persentase NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    status_hasil VARCHAR(128) NOT NULL,
    saran_tindak TEXT NOT NULL,
    checksum_sha256 VARCHAR(64) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS laporan (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    reporter_name VARCHAR(128) NOT NULL,
    jenis_masalah VARCHAR(128) NOT NULL,
    lokasi VARCHAR(128) NOT NULL,
    keterangan TEXT NOT NULL,
    foto_url TEXT,
    foto_thumb TEXT,
    status VARCHAR(32) NOT NULL DEFAULT 'terkirim',
    petugas_catatan TEXT,
    integrity_hmac VARCHAR(64) NOT NULL,
    client_ip_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_laporan_user ON laporan(user_id);
CREATE INDEX IF NOT EXISTS idx_laporan_status ON laporan(status);
CREATE INDEX IF NOT EXISTS idx_checklists_user ON checklists(user_id);