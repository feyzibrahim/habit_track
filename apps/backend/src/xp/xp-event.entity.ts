import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
} from 'typeorm';
import { User } from '../users/user.entity';

@Entity()
export class XpEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, (user) => user.xpHistory, { onDelete: 'CASCADE' })
  user: User;

  @Column()
  title: string;

  @Column()
  subtitle: string;

  @Column()
  xp: number;

  @CreateDateColumn()
  createdAt: Date;
}
