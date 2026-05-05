import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  OneToMany,
} from 'typeorm';
import { Goal } from '../goals/goal.entity';
import { Friend } from '../friends/friend.entity';
import { XpEvent } from '../xp/xp-event.entity';

@Entity()
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  email: string;

  @Column({ nullable: true })
  firstName: string;

  @Column({ nullable: true })
  lastName: string;

  @Column({ type: 'jsonb', default: { notifications: true, privacyMode: false, theme: 'dark' } })
  settings: any;

  @Column({ nullable: true })
  passwordHash: string;

  @Column({ default: false })
  isGuest: boolean;

  @OneToMany(() => Goal, (goal) => goal.user)
  goals: Goal[];

  @OneToMany(() => Friend, (friend) => friend.requester)
  sentFriendRequests: Friend[];

  @OneToMany(() => Friend, (friend) => friend.recipient)
  receivedFriendRequests: Friend[];

  @OneToMany(() => XpEvent, (xpEvent) => xpEvent.user)
  xpHistory: XpEvent[];

  @CreateDateColumn()
  createdAt: Date;
}
