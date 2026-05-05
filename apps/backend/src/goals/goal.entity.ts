import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Milestone } from './milestone.entity';

@Entity()
export class Goal {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'text' })
  prompt: string;

  @Column({ default: 'other' })
  category: string;

  @Column()
  feasibility: string; // 'not possible', 'low', 'moderate', 'can be done'

  @Column({ default: 90 })
  durationDays: number;

  @Column({ type: 'timestamp', nullable: true })
  startDate: Date;

  @Column({ type: 'timestamp', nullable: true })
  targetDate: Date;

  @Column({ default: 'planning' })
  status: string; // 'planning', 'active', 'completed', 'failed'

  @Column({ type: 'text', nullable: true })
  feasibilityReason: string;

  @Column({ type: 'text', nullable: true })
  strategicAnalysis: string;

  @Column({ type: 'int', default: 0 })
  probabilityRatio: number;

  @Column({ type: 'json', nullable: true })
  keyChallenges: string[];

  @Column({ type: 'json', nullable: true })
  graphData: any;

  @ManyToOne(() => User, (user) => user.goals)
  user: User;

  @OneToMany(() => Milestone, (milestone) => milestone.goal, { cascade: true })
  milestones: Milestone[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
