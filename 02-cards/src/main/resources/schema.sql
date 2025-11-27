CREATE TABLE IF NOT EXISTS cards (
    card_id SERIAL PRIMARY KEY,
    mobile_number VARCHAR(15) NOT NULL,
    card_number VARCHAR(100) NOT NULL,
    card_type VARCHAR(100) NOT NULL,
    total_limit INT NOT NULL,
    amount_used INT NOT NULL,
    available_amount INT NOT NULL,
    created_at DATE NOT NULL,
    created_by VARCHAR(20) NOT NULL,
    updated_at DATE DEFAULT NULL,
    updated_by VARCHAR(20) DEFAULT NULL
);