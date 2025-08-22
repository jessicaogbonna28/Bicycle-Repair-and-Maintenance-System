# Bicycle Repair and Maintenance System

A comprehensive smart contract system built with Clarity for managing bicycle repair shops, appointments, inventory, and customer services.

## System Overview

This system provides a complete solution for bicycle repair shops to manage their operations on the blockchain, ensuring transparency, trust, and efficient service delivery.

## Core Features

### 1. Repair Appointments & Diagnostics
- Schedule and manage repair appointments
- Track diagnostic results and repair recommendations
- Coordinate between customers and technicians

### 2. Parts Inventory Management
- Real-time inventory tracking
- Automatic low-stock alerts
- Parts ordering and supplier management

### 3. Service History Documentation
- Complete repair history for each bicycle
- Warranty tracking and management
- Service recommendations based on history

### 4. Transparent Pricing & Warranties
- Clear, upfront pricing for all services
- Warranty management and claims processing
- Service guarantees and quality assurance

### 5. Seasonal Maintenance & Registration
- Automated tune-up reminders
- Seasonal maintenance scheduling
- Bike registration for theft prevention

## Smart Contracts

### 1. `bike-registry.clar`
Manages bike registration, ownership, and basic information including theft prevention features.

### 2. `appointment-manager.clar`
Handles appointment scheduling, diagnostic coordination, and repair status tracking.

### 3. `inventory-system.clar`
Manages parts inventory, stock levels, and supplier relationships.

### 4. `service-history.clar`
Tracks complete service history, warranties, and maintenance records for each bike.

### 5. `pricing-warranty.clar`
Manages transparent pricing, warranty terms, and seasonal maintenance scheduling.

## Data Structures

### Bike Registration
- Unique bike ID
- Owner information
- Bike specifications (make, model, year, serial number)
- Registration status and theft prevention flags

### Appointments
- Appointment ID and scheduling details
- Customer and bike information
- Service type and diagnostic results
- Technician assignment and status

### Inventory
- Part ID and specifications
- Stock levels and reorder points
- Supplier information and pricing
- Usage tracking and forecasting

### Service Records
- Service ID and completion details
- Parts used and labor performed
- Warranty information and terms
- Quality ratings and feedback

## Getting Started

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute the test suite
5. Deploy contracts using `clarinet deploy`

## Testing

The system includes comprehensive tests using Vitest to ensure all functionality works correctly:

\`\`\`bash
npm install
npm test
\`\`\`

## Configuration

- `Clarinet.toml` - Clarinet project configuration
- `package.json` - Node.js dependencies and scripts

## Security Features

- Input validation on all contract functions
- Access control for administrative functions
- Data integrity checks and error handling
- Transparent audit trail for all operations

## Future Enhancements

- Integration with IoT sensors for bike monitoring
- Mobile app for customer notifications
- Advanced analytics and reporting
- Multi-shop franchise management
