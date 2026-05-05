import { Column, Entity, ManyToOne, OneToMany, PrimaryGeneratedColumn } from 'typeorm';
import { Milestone } from './milestone.entity';
import { TaskStep } from './task-step.entity';

@Entity()
export class ActionItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ default: 'task' })
  type: string; // 'task', 'habit'

  @Column({ nullable: true })
  frequency: string; // 'daily', 'weekly', or null for one-time task

  @Column({ default: false })
  isCompleted: boolean;

  @Column({ default: 0 })
  completedCount: number;

  @Column({ default: 1 })
  totalTarget: number;

  @Column({ type: 'timestamp', nullable: true })
  targetDate: Date;

  @Column({ default: false })
  isOptional: boolean;

  @OneToMany(() => TaskStep, (step) => step.actionItem)
  steps: TaskStep[];

  @ManyToOne(() => Milestone, (milestone) => milestone.actionItems, {
    onDelete: 'CASCADE',
  })
  milestone: Milestone;
}
