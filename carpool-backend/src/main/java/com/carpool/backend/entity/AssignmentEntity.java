package com.carpool.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(
        name = "assignments",
        indexes = {
                @Index(name = "idx_assignments_run", columnList = "run_id"),
                @Index(name = "idx_assignments_driver", columnList = "driver_id"),
                @Index(name = "idx_assignments_passenger", columnList = "passenger_id")
        }
)
public class AssignmentEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 属于哪一次分配（run）
    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "run_id", nullable = false)
    private AssignmentRunEntity run;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_id", nullable = false)
    private DriverEntity driver;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "passenger_id", nullable = false)
    private PassengerEntity passenger;

    // 这个乘客在该司机路线里的顺序（从 1 开始）
    @Column(nullable = false)
    private Integer stopOrder;

    public AssignmentEntity() {}

    public AssignmentEntity(AssignmentRunEntity run, DriverEntity driver, PassengerEntity passenger, Integer stopOrder) {
        this.run = run;
        this.driver = driver;
        this.passenger = passenger;
        this.stopOrder = stopOrder;
    }

    public Long getId() { return id; }
    public AssignmentRunEntity getRun() { return run; }
    public DriverEntity getDriver() { return driver; }
    public PassengerEntity getPassenger() { return passenger; }
    public Integer getStopOrder() { return stopOrder; }

    public void setStopOrder(Integer stopOrder) { this.stopOrder = stopOrder; }
}
